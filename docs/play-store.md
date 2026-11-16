# Publicación en Google Play (spec 048)

Flujo: `release/*` → pista **internal** (pruebas internas); `main` → pista **production** con aprobación del entorno `production`. Ambos solo después de «CI · todo verde».

Para subir una version **a mano**, sin el pipeline, ver [publicar-a-mano.md](publicar-a-mano.md).

## 1. Una sola vez en Play Console

1. Crea la app con el paquete `mx.nexolocal.app` (el `applicationId` de `android/app/build.gradle.kts`).
2. Activa **Play App Signing** (Google guarda la llave de la app; tú usas una llave de subida).
3. Sube a mano el primer AAB a *Pruebas internas*: la API de Play no puede crear la primera versión.
4. Completa lo mínimo de la ficha, clasificación de contenido y política de privacidad (spec 024) cuando vayas a producción.

## 2. Llave de subida

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

Guarda el `.jks` y las contraseñas fuera del repositorio (`.gitignore` ya excluye `*.jks` y `key.properties`). Si se pierde, hay que pedir a Google el reinicio de la llave de subida.

## 3. Firma en `android/app/build.gradle.kts`

Agrega arriba del archivo:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Y dentro de `android { … }`:

```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
```

El job «Construir · AAB firmado» escribe `android/key.properties` y `android/app/upload-keystore.jks` desde los secretos y los borra al terminar.

## 4. Cuenta de servicio para subir

1. Google Cloud: crea un proyecto y una cuenta de servicio; genera su llave JSON.
2. Play Console → *Usuarios y permisos* → invita el correo de la cuenta de servicio con permiso de *Publicar versiones* para esta app.
3. Guarda el JSON como secreto `PLAY_SERVICE_ACCOUNT_JSON` en los entornos `staging` y `production`.

## 5. Secretos y variables

| Dónde | Nombre | Valor |
|---|---|---|
| Entorno `firma` | `ANDROID_KEYSTORE_BASE64` | el base64 del `.jks` |
| Entorno `firma` | `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | contraseñas y alias (`upload`) |
| Entornos `staging`, `production` | `PLAY_SERVICE_ACCOUNT_JSON` | JSON de la cuenta de servicio |
| Variables del repo | `API_BASE_URL` (https), `API_MODE`, `PLAY_STATUS` | `draft` hasta publicar la ficha; luego `completed` |

Se pueden cargar a mano (*Settings → Environments*) o con Terraform (`manage_secrets = true`, ver [infra](../infra/github/README.md)).

## 6. Manifiesto

El job «Seguridad · AndroidManifest y build» exige en `android/app/src/main/AndroidManifest.xml`: `android:allowBackup="false"`, sin `usesCleartextTraffic="true"`, permiso `INTERNET`; y avisa si faltan los permisos de ubicación o `<queries>`.

## 7. Versión

`versionName` sale de `pubspec.yaml` (`version: 0.2.0+…`); `versionCode` = número de ejecución + `BUILD_NUMBER_OFFSET` (100). El AAB se ofusca y guarda los símbolos como artefacto para depurar fallos.

## Producción 0.3.0: push, landing y Android

1. Prepara la carpeta Android una vez (idempotente): `python3 tools/android/preparar_android.py src/mobile/nexo_app`. Agrega `allowBackup=false`, sin tráfico en claro, permisos INTERNET/ubicación/POST_NOTIFICATIONS, `<queries>`, enlace `nexolocal://`, minSdk 24, firma con `key.properties` y Google Services condicionado a `google-services.json`. Haz commit de `android/`.
2. Firebase: crea el proyecto, registra la app Android `mx.nexolocal.app`, descarga `google-services.json` y guárdalo como secreto `GOOGLE_SERVICES_JSON` del entorno `firma` (Terraform: `TF_VAR_google_services_json`). Nunca lo subas al repositorio. El backend envía los avisos con FirebaseAdmin del mismo proyecto.
3. Landing: publica `/privacidad`, `/terminos` y `/eliminar-cuenta` y pon su base en la variable `LANDING_URL` (HTTPS). Play Console pide además la URL de la política de privacidad y la de eliminación de cuenta: usa esas mismas páginas.
4. Versión: antes de abrir `release/x.y.z`, sube `version:` en `pubspec.yaml` y agrega la fila en [versionamiento](versionamiento.md).
5. El job «Construir · AAB firmado» falla si falta la firma, `GOOGLE_SERVICES_JSON`, o si `API_BASE_URL`/`LANDING_URL` no son HTTPS.
6. Declaración de datos en Play (Seguridad de los datos): ubicación aproximada y precisa, fotos, mensajes, correo, nombre, identificadores del dispositivo (push); cifrado en tránsito; el usuario puede pedir borrado.
