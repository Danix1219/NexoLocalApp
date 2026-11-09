# 040-MENSAJERIA-CHAT — Mensajes: bandeja y chat

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-040-mensajeria-chat`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [011-mensajeria](../011-mensajeria/spec.md), [025-contacto-consentimiento](../025-contacto-consentimiento/spec.md).

Fuente visual: 7.16 Mensajes (`V.inbox`, `V.chat`, `chatbar`, respuestas rápidas). Actor: Cliente o prestador. Precondición: Sesión; conversación abierta desde contacto, pedido o solicitud.

Código: `src/mobile/nexo_app/` — `lib/features/messages/inbox_page.dart`, `lib/features/messages/chat_page.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Conversar para acordar precio, fecha y lugar, con el estado del pedido visible y control de bloqueo.

## 3. Alcance / Fuera de alcance

Incluye:

- Bandeja por rol con filtro Todos/Sin leer, avatar, última vista previa, hora, estado del pedido y no leídos.
- Chat con burbujas, separadores de día, mensajes de sistema que llevan al pedido, fotos, respuestas rápidas.
- Barra superior: estado del pedido o «Pedir servicio».
- Menú: ver perfil, ver pedido, reportar, bloquear/desbloquear.
- Consulta cada 4 s y marcado de leído.

Fuera de alcance:

- Tiempo real con SignalR (deuda, spec 011).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: La bandeja muestra no leídos por conversación y el filtro «Sin leer · N».
- FR-002: El historial llega del más nuevo al más viejo y se muestra en orden cronológico con separadores Hoy/Ayer/fecha.
- FR-003: Enviar texto o foto; el mensaje propio muestra hora y palomita de leído.
- FR-004: Bloquear pide confirmación (y avisa si hay pedido activo); bloqueada, no se puede escribir y se ofrece desbloquear.
- FR-005: Al abrir el chat se marca leído hasta el último mensaje de la contraparte.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/engagement/conversations` | mensajes | bandeja |
| GET | `/v1/engagement/conversations/{id}/messages` | mensajes | historial |
| POST | `/v1/engagement/conversations/{id}/messages` | mensajes | enviar |
| POST | `/v1/engagement/conversations/{id}/read` | mensajes | leído |
| POST | `/v1/engagement/conversations/{id}/block` | mensajes | bloquear |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con 2 conversaciones sin leer el chip dice «Sin leer · 2».
- [ ] AC-002 → FR-002: Mensajes m2 (nuevo) y m1 (viejo) se muestran m1 arriba y m2 abajo.
- [ ] AC-003 → FR-003: Enviar «hola» manda `{kind:'text', text:'hola'}` y limpia el campo.
- [ ] AC-004 → FR-004: Conversación bloqueada muestra «Bloqueaste a …» y oculta el campo de texto.
- [ ] AC-005 → FR-005: Abrir un chat con 1 no leído envía `upToMessageId` del último y el globo baja.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El sondeo cada 4 s se detiene al salir del chat (Timer cancelado en dispose).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
