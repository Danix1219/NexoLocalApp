# 051-CACHE-SQLITE-SINCRONIZACION — Caché local SQLite por cuenta y sincronización al volver la señal

Versión: 0.6.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-051-cache-sqlite-sincronizacion`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [016-sincronizacion-local](../016-sincronizacion-local/spec.md), [045-resiliencia-consumo-api](../045-resiliencia-consumo-api/spec.md).

Fuente visual: Transversal; requisitos 9 (caché en frontend) y 16 (SQLite y sincronización). Actor: Cliente o prestador con o sin señal. Precondición: App instalada; SQLite disponible (si no abre, caché en memoria).

Código: `src/mobile/nexo_app/` — `lib/core/local/local_store.dart`, `lib/core/local/sqflite_store.dart`, `lib/core/local/offline_interceptor.dart`, `lib/core/local/sync_controller.dart`, `lib/core/network/api_client.dart`, `lib/core/auth/session_controller.dart`, `lib/features/shell/shell_page.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Ver lo último consultado sin señal, revalidar con el servidor sin descargar de más y no perder una solicitud publicada sin conexión.

## 3. Alcance / Fuera de alcance

Incluye:

- Caché de lecturas `GET /v1/…` por cuenta en SQLite (máx. 512 KB por respuesta y 300 por cuenta).
- Revalidación con `ETag`/`If-None-Match` (304); catálogo de categorías 1 h en el teléfono.
- Sin señal: respuesta guardada y aviso «Sin conexión. Ves lo guardado de las hh:mm».
- Cola de `POST /v1/discovery/requests` con su `Idempotency-Key`; envío al reconectar, al volver a la app y al iniciar sesión.
- Descartar y avisar si el backend rechaza por negocio; reintentar hasta 5 veces si el endpoint aún no existe.
- Borrado de caché y cola de la cuenta al cerrar sesión o si el servidor la invalida.

Fuera de alcance:

- Pedidos, contacto y chat sin conexión (spec 016: no se habilitan offline).
- Resolución de conflictos de edición (no hay ediciones en cola).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cada lectura JSON exitosa se guarda por cuenta; sin señal se responde con lo guardado y el shell muestra la hora.
- FR-002: Las lecturas guardadas se revalidan con `If-None-Match`; un 304 usa lo guardado. El catálogo se sirve del teléfono durante 1 h.
- FR-003: Publicar una solicitud sin señal la guarda en la cola con su `Idempotency-Key` y avisa que se publicará al volver la conexión; otras escrituras no se encolan.
- FR-004: Al reconectar, volver a la app o iniciar sesión se envía la cola de la cuenta; un rechazo de negocio se descarta y se avisa; un endpoint ausente se reintenta hasta 5 veces.
- FR-005: Cerrar sesión, eliminar la cuenta o una sesión invalidada borra la caché y la cola de esa cuenta; contacto, subidas, dispositivos, correo y contraseña nunca se guardan.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` |
| FR-002 | T-011 | AC-002 | `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` |
| FR-003 | T-012 | AC-003 | `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` |
| FR-004 | T-013 | AC-004 | `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` |
| FR-005 | T-014 | AC-005 | `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/cache_local_seguro_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/** (lecturas)` | todos | caché por cuenta |
| POST | `/v1/discovery/requests` | solicitudes | cola sin señal |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: `GET /v1/discovery/requests/mine` sin señal devuelve la solicitud guardada y reporta la hora 12:00.
- [ ] AC-002 → FR-002: La segunda lectura del prestador lleva `If-None-Match: "v7"` y con 304 devuelve el nombre; categorías: una llamada en 1 h y otra después.
- [ ] AC-003 → FR-003: Sin señal, `createRequest` lanza `client.queued_offline` y la cola tiene `idem-77`; `createOrder` no se encola.
- [ ] AC-004 → FR-004: Al reconectar se envía con `Idempotency-Key: idem-1` y la cola queda vacía; con 409 se descarta y se avisa el motivo.
- [ ] AC-005 → FR-005: Tras `signOutLocal` no quedan caché ni cola de `acc_1` y la cuenta `acc_2` conserva lo suyo.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- La caché SQLite no está cifrada; se mitiga con almacenamiento privado, `allowBackup=false`, datos mínimos y borrado al salir.
- Mostrar datos viejos sin señal: el aviso con la hora lo deja claro.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.6.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
