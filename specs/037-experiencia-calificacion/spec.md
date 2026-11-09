# 037-EXPERIENCIA-CALIFICACION — Mi experiencia y calificación de un servicio resuelto

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-037-experiencia-calificacion`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [020-experiencias-reputacion](../020-experiencias-reputacion/spec.md), [010-pedidos](../010-pedidos/spec.md).

Fuente visual: 7.10 Publicar — «Mi experiencia» y estrellas del pedido resuelto. Actor: Cliente con un pedido resuelto sin calificar. Precondición: Pedido en estado resolved con `canReview`.

Código: `src/mobile/nexo_app/` — `lib/features/publish/publish_page.dart`, `lib/features/orders/order_page.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Calificar con estrellas, comentario opcional y recomendación, una sola vez por pedido.

## 3. Alcance / Fuera de alcance

Incluye:

- Pestaña «Mi experiencia»: elegir prestador entre pedidos resueltos, estrellas, ¿lo recomiendas?, texto 0–280.
- Calificar desde el pedido (hoja con estrellas preseleccionadas).
- Mostrar «Tu calificación» después.

Fuera de alcance:

- Experiencias sin pedido (declaradas) — spec 020 posterior.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Solo se puede calificar un pedido resuelto y propio; sin pedidos por calificar se explica cómo llegar a uno.
- FR-002: La calificación lleva estrellas 1–5, texto opcional y recomendación, con `Idempotency-Key`.
- FR-003: Un segundo intento sobre el mismo pedido muestra el error del servidor y no duplica.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/engagement/reviews` | opiniones | calificar |
| GET | `/v1/engagement/orders?role=client` | pedidos | pedidos resueltos |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Cuenta sin pedidos resueltos ve «Aún no tienes servicios por calificar».
- [ ] AC-002 → FR-002: Elegir 4 estrellas y «No» envía `stars=4, recommend=false`.
- [ ] AC-003 → FR-003: Repetir la calificación devuelve `review.already_exists` y la pantalla lo muestra.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Moderación del texto en API (spec 005).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
