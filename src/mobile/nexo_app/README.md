# Nexo Local · app Flutter

Specs: 026–048 en [../../../specs/README.md](../../../specs/README.md). Pruebas: [pantallas y pruebas](../../../docs/pantallas-y-pruebas.md).

## Ejecutar

```bash
flutter pub get
flutter run                                   # modo auto (backend + datos de ejemplo)
flutter run --dart-define=API_MODE=live       # solo backend
flutter run --dart-define=API_MODE=fake       # solo datos de ejemplo
flutter run --dart-define=LIVE=auth,discovery --dart-define=FAKE=messages
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # backend en tu PC (emulador)
flutter run --dart-define=LANDING_URL=https://tu-landing.netlify.app
```

Por omisión usa el backend de producción en Azure (HTTPS).

## Funciones de producción (specs 049–052)

- **ML**: al agregar la foto de una solicitud se sugiere la categoría (ML Kit en el teléfono).
- **IA generativa**: «Ayúdame a redactar» en Publicar (`POST /v1/assist/draft`).
- **Push**: necesita `android/app/google-services.json` de Firebase (no se sube al repo). Sin él la app funciona sin push.
- **Sin señal**: se ve lo último guardado y publicar una solicitud queda en cola hasta que vuelva la conexión.

`API_MODE=auto` (por omisión): si un endpoint no responde (sin señal, 404/405/501, 5xx sin código de Nexo o respuesta que no es JSON), ese grupo muestra datos de ejemplo 60 s y vuelve a intentar; un error de negocio sí se muestra. Arriba aparece el aviso «datos de ejemplo». Spec 045.

## Pruebas (mismo orden que el pipeline)

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/unit
flutter test test/integration
flutter test test/security
flutter test --coverage && python3 ../../../tools/ci/cobertura.py coverage --min 45
```

Si agregas un archivo de prueba: `python3 tools/ci/generar_pipeline.py` desde la raíz del repo y commitea los archivos generados.

## Android

La carpeta `android/` la crea `flutter create .` (o la que ya tienes con el ajuste de NDK 27). Déjala lista con:

```bash
python3 ../../../tools/android/preparar_android.py .
```

Requisitos que revisa el pipeline (`tools/ci/revisar_android.py`):

- `android:allowBackup="false"` y sin `usesCleartextTraffic="true"` en `<application>`.
- Permisos `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` y `POST_NOTIFICATIONS`; minSdk 24.
- `<queries>` para `tel:`, `https:` y `whatsapp` (url_launcher).
- Firma de release desde `key.properties` (ver [Play Store](../../../docs/play-store.md)); nunca commitear la keystore.
