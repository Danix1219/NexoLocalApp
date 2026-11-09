# 027-INICIO-CLIENTE — Inicio del cliente: Para ti, Mis solicitudes y Mis servicios

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-027-inicio-cliente`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [007-descubrimiento](../007-descubrimiento/spec.md), [008-comunidad](../008-comunidad/spec.md), [009-solicitudes](../009-solicitudes/spec.md), [010-pedidos](../010-pedidos/spec.md).

Fuente visual: 7.4 Inicio — solicitante (`homeReq`, `postHTML`, `reqHTML`, `matchCard`). Actor: Cliente con sesión o visitante (solo Para ti). Precondición: Ubicación de búsqueda conocida (por defecto zona Centro, 10 km).

Código: `src/mobile/nexo_app/` — `lib/features/home/home_page.dart`, `lib/features/common/cards.dart`, `lib/features/common/carousel.dart`, `lib/features/common/actions.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Mostrar trabajos cercanos priorizando intereses, y en una segunda pestaña los servicios pedidos y las solicitudes propias con su estado.

## 3. Alcance / Fuera de alcance

Incluye:

- Pestaña Para ti con feed de trabajos (carrusel, recomendar, compartir, comparar, guardar, contactar).
- Orden por intereses declarados y por categorías de solicitudes abiertas.
- Pestaña Mis solicitudes: Mis servicios (pedidos activos o resueltos) y solicitudes con pie según estado.
- Barra de comparar flotante y buscador falso con filtros.
- Deslizar para refrescar.

Fuera de alcance:

- Publicar la solicitud (spec 035).
- Detalle del pedido (spec 039).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Para ti lista los trabajos del feed de la zona activa; primero los de categorías de interés o de solicitudes abiertas.
- FR-002: Cada publicación permite recomendar (optimista con reversión), compartir, comparar al prestador, guardar y contactar.
- FR-003: Mis solicitudes muestra Mis servicios (pedidos no cancelados ni rechazados) y cada solicitud con el pie de su estado: con pedido, con interesados, sin interesados o resuelta.
- FR-004: Con interesados, el pie muestra hasta 4 avatares, «+N» y lleva a Interesados; también permite cerrar la solicitud.
- FR-005: Sin solicitudes, se ofrece «Publicar lo que necesito».

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart` |
| FR-002 | T-011 | AC-002, AC-003 | `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart` |
| FR-003 | T-012 | AC-004 | `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart` |
| FR-004 | T-013 | AC-005 | `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart` |
| FR-005 | T-014 | AC-006 | `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/feed` | descubrimiento | trabajos cercanos |
| GET | `/v1/discovery/requests/mine` | solicitudes | mis solicitudes |
| GET | `/v1/engagement/orders?role=client` | pedidos | mis servicios |
| POST/DELETE | `/v1/discovery/works/{id}/recommend` | trabajos | recomendar |
| POST/DELETE | `/v1/discovery/saved/work/{id}` | guardados | guardar trabajo |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con interés en Pintura, el primer trabajo del feed es de Pintura cuando existe uno en la zona.
- [ ] AC-002 → FR-002: Recomendar cambia el ícono y el contador al instante; si la API falla, vuelven al valor previo y se avisa.
- [ ] AC-003 → FR-002: Comparar agrega al prestador a la barra; con 2 elegidos un tercero muestra «Ya elegiste 2».
- [ ] AC-004 → FR-003: Un pedido resuelto sin calificar muestra «Calificar»; uno pendiente «Ver pedido».
- [ ] AC-005 → FR-004: Solicitud con 6 interesados muestra 4 avatares y «+2»; tocar lleva a `/requests/{id}/interested`.
- [ ] AC-006 → FR-005: Cuenta sin solicitudes ve el vacío con acción que abre Publicar.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El feed real puede no traer `recommended`/`saved` por usuario si el contrato cambia; los modelos usan falso por omisión.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
