# Auditoría de evaluación v2 — Móvil (NexoLocalApp)

Respuestas a las secciones **2. Móvil** y **3. Pruebas de automatización** del documento *Auditoría de
evaluación v2* (18/nov/2026). Revisado el 2026-11-27 sobre `develop` + rama `fix/auditoria-movil`.

## Correcciones hechas durante la auditoría

| Hallazgo | Corrección | Dónde |
|---|---|---|
| El ML de la foto existía pero ninguna pantalla lo llamaba | Publicar llama a ML Kit al agregar la primera foto sin categoría y muestra "Por la foto parece…" | `lib/features/publish/publish_page.dart` + prueba en `test/unit/diseno_maqueta_test.dart` |
| No había suite para dispositivo físico (sección 3) | `integration_test/app_dispositivo_test.dart` (5 flujos de la app completa) y `tools/pruebas-dispositivo.ps1` | ver "Sección 3" abajo |
| El buscador no entendía el problema escrito | La app muestra "Mostrando Plomería para «…»" cuando la API deduce la categoría | rama `feature/buscador-intencion` |

## Respuestas

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | % de seguridad DevSecOps | **≈ 80 %** (estimación propia): secretos, SCA, análisis estático, revisión de manifest y workflows, almacenamiento seguro, TLS, ofuscación y pruebas de seguridad cubiertos; faltan *certificate pinning*, detección de root/integridad y DAST móvil (MobSF) |
| 2 | OWASP Top 10 / Mobile Top 10 | **Cumple la mayoría.** M1 credenciales: tokens en `flutter_secure_storage`, nada en código (prueba `secretos_en_codigo_test`). M3 auth: OAuth2 + refresh + logout en servidor. M4 entradas: validación en formularios y en la API. M5 comunicación: solo HTTPS, `usesCleartextTraffic=false` (prueba `transporte_test`). M6 privacidad: logs sin datos sensibles, IA sin datos personales. M8 configuración: `allowBackup=false`, enlaces profundos validados. M9 almacenamiento: caché local cifrada/limpia al salir. M7 binario: R8 + `--obfuscate`. **Parcial:** M5 sin *pinning*, M7 sin detección de root/manipulación |
| 3 | Vulnerabilidades críticas | **Ninguna crítica conocida** (OSV sobre `pubspec.lock` sin hallazgos bloqueantes). Riesgos medios: sin *pinning* y sin detección de root |
| 4 | ¿Nivel bancario/fintech? | **No.** Un banco exigiría *pinning*, Play Integrity/detección de root, RASP y pentest externo |
| 5 | DevSecOps en CI | gitleaks, **OSV-Scanner** (dependencias), revisión de dependencias del PR, `flutter analyze`, revisión de AndroidManifest y build, actionlint + permisos de workflows, pruebas de seguridad por archivo, cobertura combinada, matriz de versión SemVer |
| 6 | DevSecOps en CD | AAB **firmado** con llave fuera del repo (secretos), `--obfuscate --split-debug-info`, R8/ProGuard, publicación a Play Console (pruebas internas → producción) con aprobación |
| 7 | Endpoints consumidos | **≈ 70 rutas** de la API (identidad, perfil, descubrimiento, trabajos, solicitudes, interés, pedidos, opiniones, mensajes y chat cifrado, guardados, contacto/reportes, notificaciones, imágenes, asistente) + hub SignalR `/hubs/chat` (`lib/data/http_nexo_api.dart`) |
| 8 | Agentes de IA | **2**: Codex y Claude Code (`AGENTS.md`, `CLAUDE.md`) |
| 9 | Skills | **Sí, en el entorno de Claude Code** (instaladas a nivel de usuario, no versionadas en el repo por regla del equipo): `code-review` y `security-review` (integradas), `ui-ux-pro-max` (diseño de pantallas), `playwright-cli` (pruebas de navegador) y `graphify` (mapa del código) |
| 10 | Memoria.md | **Sí**, `Memoria.md` en la raíz del repo |
| 11 | Pruebas unitarias | **Sí.** Suite completa con Flutter 3.38.10: **359 pruebas aprobadas** en total (`test/unit` 174 declaraciones, varias parametrizadas) |
| 12 | Pruebas de seguridad | **Sí**, `test/security`: 9 archivos, 61 casos (secretos, transporte, push, enlaces profundos, caché, cabeceras/subidas, privacidad, IA sin datos personales, logs) |
| 13 | Pruebas de integración | **Sí**, `test/integration`: 14 archivos, 113 casos (contratos HTTP de cada grupo, sesión, sincronización sin conexión, resiliencia, push) |
| 14 | Pantallas con consumo sin alguna prueba | Mapa (`/v1/discovery/map/nearby`): sin prueba de seguridad. Comparar prestadores: solo integración. Pantallas del chat cifrado: unitarias e integración HTTP, sin prueba en dos dispositivos reales. Notificaciones (bandeja): integración, sin prueba de seguridad propia |
| 15 | Otras pruebas | Pruebas de widgets/diseño contra la maqueta, accesibilidad (movimiento reducido), **suite en dispositivo físico** (`integration_test`), pruebas nativas de Signal (chat cifrado), verificación de que el pipeline tiene un job por archivo de prueba |
| 16 | MCP | **Ninguno** configurado en el proyecto |
| 17 | Validación de imágenes inapropiadas | **Sí**: la app limita tipo (JPEG/PNG/WebP), tamaño (5 MB) y dimensiones; la API modera cada imagen con **Azure AI Content Safety** antes de aprobarla (`upload.rejected_by_moderation`) |
| 18 | Validación de texto inapropiado | **Sí**: Content Safety + lista de groserías en español `nexo-groserias-es` (160 términos) en publicaciones, perfiles, opiniones y asistente (403 `content.inappropriate`). El chat cifrado E2EE no puede moderarse (decisión documentada); conserva bloqueo y reporte |
| 19 | Eliminar cuenta | **Sí**: Cuenta → Eliminar cuenta, con contraseña y aviso de lo irreversible (`POST /v1/identity/me/deletion`, con opción de cancelar) |
| 20 | Permisos | `INTERNET`, `ACCESS_COARSE_LOCATION` / `ACCESS_FINE_LOCATION` (prestadores cercanos), `POST_NOTIFICATIONS` (push), `RECORD_AUDIO` (notas de voz del chat, se pide al grabar). Las fotos usan el selector del sistema (sin permiso de almacenamiento) |
| 21 | ¿Persiste la sesión? | **Sí**: el refresh token vive en `flutter_secure_storage` (Keystore); al reabrir, el splash restaura la sesión sin pedir login |
| 22 | Machine Learning | **Google ML Kit Image Labeling en el teléfono**: al agregar una foto en Publicar sugiere la categoría ("Por la foto parece Plomería, 72 %"). Además, la búsqueda usa el clasificador ML.NET del servidor |
| 23 | IA generativa | **Asistente de redacción** (`POST /v1/assist/draft`, Azure OpenAI `gpt-4.1-mini`): convierte lo que escribe la persona en un borrador claro de solicitud o de trabajo; quita teléfonos/correos y pasa por moderación |
| 24 | Logout con endpoint | **Sí**: `POST /v1/identity/logout` (revoca refresh token y access token en Redis) y luego borra el almacenamiento local |
| 25 | Push | **Sí, FCM.** Flujos: nuevo interesado en tu solicitud, pedido creado/aceptado/rechazado/cancelado/terminado/cambio de dirección, mensaje recibido (datos sin contenido, la app descifra), opinión recibida. Toque → abre la pantalla por enlace profundo |

## Sección 3 · Suite automatizada en dispositivo físico

Requisitos: **Flutter 3.38.10**, teléfono Android con depuración USB autorizada (`adb devices` lo muestra como `device`).

Desde `src/mobile/nexo_app`:

```powershell
powershell -ExecutionPolicy Bypass -File tools/pruebas-dispositivo.ps1
```

o directo:

```powershell
flutter test integration_test --dart-define=API_MODE=fake -d <id-del-dispositivo>
```

Flujos que recorre sobre la app completa: (1) arranque y bienvenida, (2) login rechaza un correo inválido,
(3) invitado navega por las pestañas, (4) búsqueda muestra resultados, (5) publicar como invitado pide cuenta.
Con `-Modo live` usa la API desplegada en lugar de los datos de ejemplo.

Estado: el código compila y pasa `flutter analyze`. **Falta correrla en un teléfono real**: en el simulador de
pruebas de la PC no corre porque los plugins nativos (conectividad, almacenamiento seguro) solo existen en el dispositivo.

Las pruebas de unidad, integración y seguridad también se pueden correr con el teléfono conectado:

```powershell
flutter test test
```
