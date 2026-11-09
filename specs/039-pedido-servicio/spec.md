# 039-PEDIDO-SERVICIO — Pedido de servicio: pedir, aceptar, rechazar, cancelar, resolver y domicilio

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-039-pedido-servicio`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [010-pedidos](../010-pedidos/spec.md), [025-contacto-consentimiento](../025-contacto-consentimiento/spec.md).

Fuente visual: 7.15 Pedido (`V.match`, `agSheet`, pasos Pedido · Aceptado · Resuelto). Actor: Cliente y prestador participantes. Precondición: Pedido existente o prestador elegido.

Código: `src/mobile/nexo_app/` — `lib/features/orders/order_page.dart`, `lib/features/common/actions.dart`, `lib/data/http_nexo_api.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Registrar el acuerdo entre cliente y prestador con estados claros, precio informativo y dirección visible solo cuando corresponde.

## 3. Alcance / Fuera de alcance

Incluye:

- Hoja «Pedir servicio»: servicio, qué necesitas (10+), dónde (domicilio con mapa o local) y dirección.
- Pantalla del pedido: pasos, lugar, contraparte, lo acordado, acciones por rol y estado, historial.
- Aceptar con precio opcional, rechazar con motivo, cancelar, marcar resuelto con precio final, cambiar domicilio.
- `If-Match` con la versión vista; ante 409/412 recargar y avisar.

Fuera de alcance:

- Pagos dentro de la app.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Pedir envía `origin=direct` desde perfil o `origin=post` desde interesados, con `Idempotency-Key`; un activo duplicado muestra el error del servidor.
- FR-002: Las acciones visibles salen de `allowedActions`; cada una manda `If-Match` con la versión mostrada.
- FR-003: Con un pedido pendiente, el prestador ve la zona aproximada y no la dirección ni el teléfono del cliente (H02).
- FR-004: Un conflicto de versión (412/409) recarga el pedido y avisa sin aplicar la acción.
- FR-005: Con el pedido resuelto, el cliente califica con estrellas desde la misma pantalla (spec 037).

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001, AC-002 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-002 | T-011 | AC-003 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-003 | T-012 | AC-004 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-004 | T-013 | AC-005 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| FR-005 | T-014 | AC-006 | `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/privacidad_test.dart`, `test/security/cabeceras_y_subidas_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/engagement/orders` | pedidos | pedir |
| GET | `/v1/engagement/orders/{id}` | pedidos | detalle |
| POST | `/v1/engagement/orders/{id}/accept|reject|cancel|resolve` | pedidos | acciones |
| PUT | `/v1/engagement/orders/{id}/address` | pedidos | domicilio |
| POST | `/v1/engagement/contacts/phone` | contacto | copiar número |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Pedir desde Interesados envía `requestId` y `origin=post`; desde el perfil, sin `requestId` y `origin=direct`.
- [ ] AC-002 → FR-001: Segundo pedido activo al mismo prestador muestra «Ya tienes un pedido activo con este prestador».
- [ ] AC-003 → FR-002: Aceptar el pedido versión 3 envía `If-Match: "3"`.
- [ ] AC-004 → FR-003: Pedido pendiente visto por el prestador: sin dirección, mapa con círculo, sin «Copiar número».
- [ ] AC-005 → FR-004: Aceptar con versión vieja muestra el aviso y el estado no cambia.
- [ ] AC-006 → FR-005: Pedido resuelto sin calificar muestra «¿Cómo te fue con …?» con estrellas.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- La dirección escrita no se valida con geocodificación (deuda).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
