# Integración de Identity y Cuenta — 2026-11-09

Se conserva Flutter, Riverpod, Dio, go_router y las tres capas actuales de pruebas.
La API de `NexoLocalApi/specs/endpoints/01-auth` y `02-cuenta` es la autoridad del contrato.

Cuenta consume GET /v1/identity/me (objeto plano), PATCH /me, POST /me/mode,
POST /me/phone, POST/DELETE /me/deletion y POST/DELETE /devices.
El cambio de modo renueva el refresh token si `tokenRefreshRequired=true` y reinicia navegación.
La insignia representa emailVerifiedAt; el teléfono es contacto declarado y no solicita SMS.
La solicitud de baja cierra la sesión revocada. Un nuevo login con recovery_only=true
lleva a Cuenta para conservarla o cerrar sesión; al cancelar se renueva el token.
GET /me no se sirve desde caché. Cuenta y dispositivos en auto usan siempre el servidor:
una falla no debe simular una baja, registro de dispositivo o identidad válida.
El resto de grupos mantiene API_MODE=auto y el aviso de datos de ejemplo.

## Pruebas

Se ampliaron los archivos existentes test/unit/auth_parsing_test.dart,
test/integration/http_cuenta_test.dart y test/security/privacidad_test.dart.
Los adaptadores HTTP de esas pruebas son simulados: no prueban SMTP, Atlas o Firebase.
No se agregó un archivo de pruebas: no cambia el inventario de jobs del generador.

## Ejecución

Desde src/mobile/nexo_app:
```powershell
flutter pub get
flutter analyze --no-fatal-infos
flutter test --coverage
flutter run --dart-define=API_BASE_URL=https://TU_BACKEND --dart-define=LIVE=cuenta,dispositivos
```
Para Android emulado y backend HTTP local usa http://10.0.2.2:PUERTO solo en debug.
No se cambió el servidor de producción por omisión ni se publicaron recursos.
El backend debe incluir la rama 02-cuenta. Editar nombre requiere ContentSafety configurado.
La carga de fotos y el perfil prestador dependen de endpoints todavía pendientes del backend.
La app conserva sus pantallas existentes de registro, correo, código, login y recuperación.
La entrega no certifica el recorrido de registro y cuenta con Gmail, Atlas o Firebase reales.

## Evidencia local de entrega

- Suite completa con cobertura: 215/215 aprobadas en el repositorio móvil.
- Analizador: 0 errores y 0 warnings; 10 observaciones de estilo existentes (exit 0 con --no-fatal-infos).
- Generador CI: PIPELINE-OK, 53 checks; archivos actuales de las tres capas ampliados.
- Android: NDK fijado en 27.0.12077973 para coincidir con los plugins instalados.
- SDD global: enlaces históricos a docs_nexo, requerimientos_nexolocal y API_NexoLocal no disponibles en este checkout; no se certifica SDD-OK.

## Verificación Android completada

APK debug compilado correctamente, instalado con `adb install -r` conservando datos existentes y actividad principal iniciada con `Status: ok`. El proceso continuó activo en la comprobación posterior; la consulta de AndroidRuntime:E y flutter:E para ese proceso no devolvió errores. Esta evidencia confirma instalación y arranque, no aceptación funcional de todos los recorridos.

APK: `src/mobile/nexo_app/build/app/outputs/flutter-apk/app-debug.apk`.


### 2026-11-09 — Ubicacion real y Mi perfil

Registro: mapa/GPS con consentimiento, seleccion obligatoria y envio del punto/radio elegidos. Tras el alta se guarda en Discovery. Cuenta: PUT real, sin fallback de guardado simulado; seleccion local segura aislada por accountId. GPS sin permiso o apagado permite mover el mapa. No hay geocodificacion de colonias: mostrar coordenadas aproximadas, nunca nombres de zonas ficticios.

Mi perfil se abre desde la tarjeta propia con portada visual, foto disponible, nombre, correo verificado y accion separada de editar. Actividad sin implementar aparece proximamente. Fotos se anuncian proximamente por confirmacion del usuario: Blob Storage y moderacion no configurados; no se crearon recursos cloud.

Las rutas inexistentes (404/405/501 sin codigo Nexo) muestran Proximamente sin boton Reintentar. Errores de autenticacion, red y negocio mantienen su tratamiento. Pruebas ampliadas en archivos existentes de integracion/seguridad; no se agregan jobs ni se aplica Terraform.

Verificacion del incremento: 217 pruebas Flutter aprobadas con cobertura; 97 pruebas backend aprobadas. APK debug con API local compilado, instalado conservando datos y abierto en Android (Status: ok). Endpoint PUT de ubicacion disponible en 5188; peticion anonima devuelve 401. GPS sobre hardware y recorrido de alta/cambio con usuario real quedan para comprobacion interactiva del usuario. Etiquetas de ubicacion muestran coordenadas aproximadas: geocodificacion de colonias pendiente. No se configuro ni simulo Blob/moderacion.
