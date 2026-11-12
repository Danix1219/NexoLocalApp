# Publicar la app a mano en Google Play

Guía completa para subir una versión de Nexo Local a Google Play sin usar el
pipeline: desde clonar el repositorio hasta dejar la versión disponible para
los testers.

Si lo que quieres es el despliegue automático desde GitHub Actions, esa parte
está en [play-store.md](play-store.md). Esta guía es para hacerlo a mano.

**Antes de empezar, dos avisos que ahorran días:**

- La **llave de firma no se puede cambiar** una vez subida la primera versión.
  Si publicas con una llave y la pierdes, hay que pedirle a Google que la
  reinicie, y eso tarda. Respáldala en cuanto la generes.
- El **`versionCode` nunca puede repetirse ni bajar**. Play rechaza el bundle
  sin más explicación. Lleva la cuenta en [versionamiento.md](versionamiento.md).

---

## 0. Qué necesitas instalado

| Herramienta | Para qué | Cómo comprobar |
|---|---|---|
| Flutter 3.29 / Dart 3.7 | Compilar la app | `flutter --version` |
| JDK 17 | Gradle y `keytool` | `java -version` |
| Android SDK | Compilar para Android | `flutter doctor` |
| Git | Bajar el código | `git --version` |

Si `flutter doctor` marca algo en rojo en la sección de Android, resuélvelo
antes de seguir: el build de release falla más adelante y el mensaje no
siempre apunta a la causa.

---

## 1. Bajar el código

```powershell
git clone https://github.com/Danix1219/NexoLocalApp.git
cd NexoLocalApp\src\mobile\nexo_app
flutter pub get
```

Comprueba que compila y que las pruebas pasan antes de pensar en publicar:

```powershell
flutter analyze
flutter test
```

Si `flutter test` falla, **no publiques**. Arregla eso primero.

---

## 2. Crear la llave de firma

Solo la primera vez. Si ya existe una llave del proyecto, pídesela a quien la
tenga y salta al paso 3.

```powershell
keytool -genkey -v -keystore $HOME\nexo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Te va a preguntar, en este orden: contraseña del almacén, nombre y apellidos,
unidad organizativa, organización, ciudad, estado y código de país (`MX`), y
al final una confirmación donde **se responde `si`**, no `yes`, si el programa
está en español.

> **Guarda el archivo `.jks` y las dos contraseñas en un lugar seguro y fuera
> del repositorio.** Sin ellos no se pueden publicar actualizaciones de la app.

### Decirle al proyecto dónde está la llave

Crea `src/mobile/nexo_app/android/key.properties` con este contenido, usando
tus valores reales:

```properties
storePassword=LA_CONTRASEÑA_DEL_ALMACEN
keyPassword=LA_CONTRASEÑA_DE_LA_CLAVE
keyAlias=upload
storeFile=C:/Users/TU_USUARIO/nexo-release.jks
```

Detalles que hacen fallar esto:

- La ruta va con **barras normales** (`/`), aunque sea Windows.
- Ese archivo **está en `.gitignore`**. No lo subas al repositorio ni lo
  mandes por chat.
- Si el archivo no existe, el build usa la llave de depuración y **Play
  rechaza el bundle**.

---

## 3. Comprobar la configuración de Android

```powershell
cd ..\..\..
python tools\android\preparar_android.py src\mobile\nexo_app
```

Es idempotente: si ya está todo, dice «Sin cambios». Deja puesto
`allowBackup=false`, sin tráfico en claro, los permisos mínimos, `minSdk 24`,
la firma de release y los símbolos nativos.

Verificación rápida:

```powershell
python tools\ci\revisar_android.py
```

Tiene que decir `ANDROID-OK`.

---

## 4. Subir la versión en el código

Edita `src/mobile/nexo_app/pubspec.yaml`:

```yaml
version: 0.3.2+302
```

El número antes del `+` es lo que ve la gente; el de después es el
`versionCode`, que **debe ser mayor que el de la última versión subida a Play**.

Después añade la fila correspondiente en `docs/versionamiento.md` y comprueba:

```powershell
python tools\ci\versionamiento.py
```

Tiene que decir `VERSION-OK`. Si dice que la versión no está en la matriz, es
que falta esa fila.

---

## 5. Generar el AAB firmado

```powershell
cd src\mobile\nexo_app
flutter build appbundle --release --dart-define=API_BASE_URL=https://nexolocal-ekfpbudfewd4g0cp.northcentralus-01.azurewebsites.net --dart-define=LANDING_URL=https://danix1219.github.io/NexoLocalApp/legal
```

Tarda entre 10 y 15 minutos la primera vez. El resultado queda en:

```
src\mobile\nexo_app\build\app\outputs\bundle\release\app-release.aab
```

Los dos `--dart-define` **no son opcionales**: sin ellos la app apunta a
valores por defecto y la pantalla del aviso de privacidad no aparece.

### Comprobar que el AAB es el correcto

No te fíes de que el build terminó. Revisa lo que lleva dentro:

```powershell
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

Debe mostrar el propietario de **tu** llave, no `CN=Android Debug`.

```powershell
Select-String -Path build\app\intermediates\bundle_manifest\release\*\AndroidManifest.xml -Pattern 'minSdkVersion|targetSdkVersion|package='
```

Debe decir `minSdkVersion="24"`, `targetSdkVersion="36"` y
`package="mx.nexolocal.app"`.

Si sale `com.example` en algún lado, el build no tomó la configuración
correcta y Play lo va a rechazar.

### Probarlo en un teléfono antes de subirlo

```powershell
flutter run --release --dart-define=API_BASE_URL=https://nexolocal-ekfpbudfewd4g0cp.northcentralus-01.azurewebsites.net --dart-define=LANDING_URL=https://danix1219.github.io/NexoLocalApp/legal
```

Con el teléfono conectado por USB y la depuración USB activada. Comprueba al
menos: que inicia sesión, que el catálogo carga y que el icono en el escritorio
es el de Nexo Local y no el de Flutter.

---

## 6. Los avisos legales

Google exige una URL pública de política de privacidad y otra de eliminación
de cuenta. Ya existen, servidas por GitHub Pages desde `docs/legal` en la rama
`develop`:

| Documento | URL |
|---|---|
| Índice | https://danix1219.github.io/NexoLocalApp/legal/ |
| Aviso de privacidad | https://danix1219.github.io/NexoLocalApp/legal/privacidad/ |
| Términos de uso | https://danix1219.github.io/NexoLocalApp/legal/terminos/ |
| Eliminar cuenta | https://danix1219.github.io/NexoLocalApp/legal/eliminar-cuenta/ |

**Si cambias algo de cómo la app trata los datos, hay que actualizar el aviso
de privacidad antes de publicar.** No es un formalismo: el aviso está redactado
conforme a los artículos 16 y 17 de la LFPDPPP y describe el comportamiento
real del código. Declarar algo que la app no hace, o callar algo que sí hace,
es lo que se sanciona.

Los archivos están en `docs/legal/`. Para que un cambio llegue a la web tiene
que mezclarse en `develop`, que es la rama que publica GitHub Pages.

---

## 7. Subir a Play Console

### La primera vez: crear la app

1. **Crear aplicación.** Nombre `Nexo Local`, paquete `mx.nexolocal.app`,
   idioma español, tipo Aplicación, **Sin coste** (irreversible).
2. Acepta las tres declaraciones: políticas, firma de apps de Play y leyes de
   exportación de EE. UU.

### Subir la versión

**Prueba interna > Crear una versión:**

1. Acepta la **firma de apps de Google Play** si te la ofrece. Tu `.jks` queda
   como llave de subida; Google firma la app con otra propia.
2. Arrastra `app-release.aab`.
3. **Nombre de la versión:** el mismo del pubspec, por ejemplo `0.3.2 (302)`.
4. **Notas de la versión:** dentro de las etiquetas del idioma, describiendo
   qué cambió. Si hay secciones con datos de ejemplo, dilo ahí.
5. Pestaña **Verificadores:** una lista con los correos de Gmail del equipo.
6. **Revisar versión** → **Iniciar lanzamiento**.

Te da un enlace de aceptación que repartes. Cada persona lo abre, acepta, y ya
puede instalar desde Play.

---

## 8. Las declaraciones del panel

La prueba interna no las exige, pero la prueba cerrada y producción sí. Estas
son las respuestas que corresponden a la app tal como está hoy:

| Declaración | Respuesta |
|---|---|
| Política de privacidad | La URL de arriba, la de `privacidad/` |
| **Datos de inicio de sesión** | Sí, hay partes restringidas. Credenciales de una cuenta de prueba viva, **y el texto en inglés** |
| Anuncios | No contiene anuncios |
| **Clasificación de contenido** | Categoría «Todos los demás tipos de aplicaciones» |
| Audiencia objetivo | Solo **18 y más** |
| **Seguridad de los datos** | Ver el detalle abajo |
| Aplicaciones gubernamentales | No |
| Funciones financieras | «No proporciona funciones financieras» |
| Salud | No |
| Categoría de la tienda | Casa y hogar |

### Clasificación de contenido

Todo en **No**, salvo:

- Usuarios interactúan o intercambian contenido → **Sí**
- El contenido del usuario es el origen principal → **Sí**
- Capacidad de bloquear → **Sí**
- Capacidad de reportar → **Sí**
- Moderación de chat → **Sí**
- Contenido en línea fuera de la descarga → **Sí**

Resultado esperado: 12+ en todos los territorios.

### Seguridad de los datos

- Cifrado en tránsito: **Sí**
- Creación de cuenta: **Nombre de usuario y contraseña**
- URL de eliminación de cuentas: la de `eliminar-cuenta/`

Tipos de datos que se recogen. **Todos marcados como «Se recogen», ninguno
como «Se comparten»**: Azure, Firebase y el proveedor de IA son encargados que
tratan datos por cuenta nuestra, y lo que ve la otra parte de un servicio es
una acción iniciada por la persona. Las dos cosas están exentas.

| Tipo | ¿Necesario? | Para qué |
|---|---|---|
| Nombre | Necesario | Funcionalidad, Gestión de cuentas |
| Correo electrónico | Necesario | Funcionalidad, Gestión de cuentas, Prevención de fraudes |
| Dirección | Opcional | Funcionalidad |
| Teléfono | Opcional | Funcionalidad |
| Ubicación aproximada y precisa | Opcional | Funcionalidad |
| Mensajes | Opcional | Funcionalidad |
| Fotos | Opcional | Funcionalidad |
| Actividad en aplicaciones | Opcional | Funcionalidad |
| IDs de dispositivo | Opcional | Funcionalidad |

**No marques Contactos ni Información financiera.** La app no lee la agenda
del teléfono y no procesa pagos. Si aparecen preseleccionados, quítalos.

---

## 9. La ficha de Play Store

| Recurso | Dónde está |
|---|---|
| Icono 512×512 | `docs/img/nexolocal_icono_512.png` |
| Gráfico destacado 1024×500 | `docs/img/nexolocal_grafico_destacado_1024x500.png` |
| Capturas de pantalla | Hay que sacarlas del teléfono |

Las capturas: mínimo 2, pero **sube 4 o más de 1080×1080 px o mayores** o Play
no puede promocionar la app. Captura el catálogo con resultados, un perfil con
trabajos, la pantalla de publicar y el chat. Que no salgan pantallas vacías ni
datos reales de nadie.

---

## 10. Cosas que fallan y por qué

| Síntoma | Causa |
|---|---|
| «La protección automática requiere SDK 24 o posterior» | `minSdk` menor a 24 en `build.gradle.kts` |
| «Debes usar un paquete diferente» | El `applicationId` sigue siendo `com.example.*` |
| «Ya se ha usado el código de versión» | El `versionCode` del pubspec repite uno subido |
| «El APK está firmado con el certificado de depuración» | Falta `key.properties` o la ruta del `.jks` es incorrecta |
| El keystore no se lee en el CI | El Base64 se generó con `certutil`, que mete saltos de línea. Usa `[Convert]::ToBase64String(...)` |
| `Duplicate class FirebaseInstanceIdReceiver` | Falta la exclusión de `firebase-iid`. Corre `preparar_android.py` |
| La app abre pero no carga nada | Faltó `--dart-define=API_BASE_URL`, o el App Service de Azure está apagado |
| Google rechaza por no poder acceder | La cuenta de prueba declarada no existe o el backend estaba caído durante la revisión |

---

## 11. Lo que hay que saber antes de prometer nada

Estas limitaciones son reales y están verificadas en el código. Conviene
conocerlas antes de declarar algo en Play Console:

- **El sanitizador del asistente de redacción deja pasar datos**: formatos como
  `juan(arroba)gmail.com`, `[at]`/`[dot]`, Unicode de ancho completo y
  direcciones escritas en texto corrido. Ese contenido sale del teléfono hacia
  el proveedor de IA. El aviso de privacidad lo advierte expresamente.
- **Los endpoints `/v1/assist/draft` y `/v1/identity/devices` no existen en el
  backend.** La app cae a datos de demostración sin avisar al usuario.
- **`SqfliteLocalStore` no tiene pruebas.**
- **El backend de Azure tiene que estar encendido durante la revisión de
  Google**, que puede tardar días. Si se apaga para ahorrar, el revisor ve una
  app que no deja iniciar sesión y la rechaza.
