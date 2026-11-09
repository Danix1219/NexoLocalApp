# 052-PRIVACIDAD-LANDING-PRODUCCION — Aviso de privacidad en la landing, moderación, permisos Android y versionamiento para producción

Versión: 0.6.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-052-privacidad-landing-produccion`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [023-privacidad-permisos-enlaces](../023-privacidad-permisos-enlaces/spec.md), [024-landing-evaluacion](../024-landing-evaluacion/spec.md), [014-entrega](../014-entrega/spec.md), [041-cuenta-modo-celular-baja](../041-cuenta-modo-celular-baja/spec.md).

Fuente visual: Cuenta → Privacidad y cuenta; requisitos 11, 16 y 17 del profesor. Actor: Cualquier persona con la app; responsable de entrega. Precondición: `LANDING_URL` con las páginas `/privacidad`, `/terminos` y `/eliminar-cuenta`.

Código: `src/mobile/nexo_app/` — `lib/features/auth/presentation/legal_sheets.dart`, `lib/features/account/account_page.dart`, `lib/app/env.dart`, `lib/core/widgets/ui.dart`, `tools/android/preparar_android.py`, `tools/ci/versionamiento.py`, `tools/ci/preparar_firebase.py`, `docs/versionamiento.md`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Que el build de producción cumpla los lineamientos: aviso de privacidad vinculado a la landing, eliminar cuenta, permisos mínimos, mensajes claros de moderación y una versión verificada contra la matriz.

## 3. Alcance / Fuera de alcance

Incluye:

- Aviso y términos con resumen en la app y botón «Ver versión completa» a la landing; enlace «Qué datos se borran» al eliminar cuenta.
- Mensajes para `content.inappropriate`, `upload.rejected_by_moderation` y `content.images_limit`.
- Script `tools/android/preparar_android.py`: `allowBackup=false`, sin tráfico en claro, permisos INTERNET/ubicación/POST_NOTIFICATIONS, `<queries>`, enlace `nexolocal://`, minSdk 23, firma y Google Services.
- Matriz `docs/versionamiento.md` y job «Versión · matriz y SemVer».
- Release: backend HTTPS de producción por omisión, `LANDING_URL` HTTPS y Firebase obligatorios en el AAB.

Fuera de alcance:

- Contenido legal definitivo (lo redacta y publica la landing).
- Ficha de Play Store.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Aviso de privacidad y términos muestran un resumen y abren la versión completa de la landing (solo HTTPS).
- FR-002: Eliminar cuenta enlaza la página de la landing que explica qué se borra y qué se conserva.
- FR-003: Un rechazo de moderación de texto o foto muestra un mensaje claro y no publica.
- FR-004: El manifiesto de release no permite respaldo ni tráfico en claro y solo pide INTERNET, ubicación y notificaciones.
- FR-005: La versión del `pubspec.yaml` está en la matriz y coincide con la rama `release/x.y.z`.
- FR-006: El AAB de producción falla si `API_BASE_URL` o `LANDING_URL` no son HTTPS o si falta `GOOGLE_SERVICES_JSON`.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| FR-002 | T-011 | AC-002 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| FR-003 | T-012 | AC-003 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| FR-004 | T-013 | AC-004 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| FR-005 | T-014 | AC-005 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| FR-006 | T-015 | AC-006 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/transporte_test.dart`, `test/security/secretos_en_codigo_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/identity/me/deletion` | cuenta | solicitar baja (spec 041) |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con `LANDING_URL=https://…` el aviso muestra «Ver versión completa» y abre `/privacidad`; con `http://` no se muestra.
- [ ] AC-002 → FR-002: La hoja de eliminar cuenta muestra «Qué datos se borran y cuáles se conservan» hacia `/eliminar-cuenta`.
- [ ] AC-003 → FR-003: Con 403 `content.inappropriate` al publicar, el aviso dice que no cumple las reglas de la comunidad.
- [ ] AC-004 → FR-004: `revisar_android.py` falla sin `allowBackup=false` o sin `POST_NOTIFICATIONS`; `preparar_android.py` los agrega y es idempotente.
- [ ] AC-005 → FR-005: En `release/0.3.1` con `version: 0.3.0+300` el job de versión falla.
- [ ] AC-006 → FR-006: Sin `GOOGLE_SERVICES_JSON` el paso de Firebase del AAB falla con mensaje claro.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- La landing debe publicar las tres páginas antes del AAB de producción.
- El texto legal dentro de la app es un resumen; el vigente es el de la landing.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.6.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
