# 028-INICIO-PRESTADOR — Inicio del prestador: Comunidad, Oportunidades y pedidos por responder

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-028-inicio-prestador`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [009-solicitudes](../009-solicitudes/spec.md), [010-pedidos](../010-pedidos/spec.md), [021-interesados-candidatos](../021-interesados-candidatos/spec.md), [006-perfiles](../006-perfiles/spec.md).

Fuente visual: 7.5 Inicio — prestador (`homePro`, `provPendHTML`, `reqHTML` ajena). Actor: Prestador en modo Proveedor. Precondición: Sesión en modo prestador; perfil de prestador creado (si no, se ofrece crearlo).

Código: `src/mobile/nexo_app/` — `lib/features/home/home_page.dart`, `lib/features/common/cards.dart`, `lib/features/search/filters.dart`, `lib/features/common/actions.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Dar al prestador las solicitudes que coinciden con su servicio y zona, sus pedidos por responder y aceptados, y trabajos de su rubro.

## 3. Alcance / Fuera de alcance

Incluye:

- Pestaña Comunidad: trabajos de sus categorías de otros prestadores.
- Pestaña Oportunidades: pedidos por responder, pedidos aceptados, solicitudes para ti y áreas de oportunidad del perfil.
- «Me interesa» / «Interés enviado», guardar solicitud y «Te eligió».
- Filtros de oportunidades (radio, servicio, urgentes, categoría).

Fuera de alcance:

- Aceptar o rechazar en detalle (spec 039).
- Edición del perfil (spec 032).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Sin perfil de prestador, Inicio en modo Proveedor ofrece crear el perfil (spec 044) y no llama a oportunidades.
- FR-002: Oportunidades lista primero pedidos por responder, luego aceptados y después solicitudes para ti ordenadas por coincidencia y urgencia.
- FR-003: «Me interesa» envía o retira el interés y actualiza el botón; si el cliente ya eligió a otro, se muestra «Eligió a otro prestador».
- FR-004: Los filtros (dentro de mi radio, coincide con mi servicio, urgentes, categoría) se aplican a la consulta y muestran su conteo.
- FR-005: Áreas de oportunidad muestra el porcentaje del perfil y el siguiente pendiente con acceso a completarlo.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart` |
| FR-003 | T-012 | AC-003, AC-004 | `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart` |
| FR-004 | T-013 | AC-005 | `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart` |
| FR-005 | T-014 | AC-006 | `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/requests/opportunities` | solicitudes | solicitudes para ti |
| GET | `/v1/engagement/orders?role=provider` | pedidos | pendientes y aceptados |
| GET | `/v1/discovery/providers/me` | perfil | perfil propio y completitud |
| POST/DELETE | `/v1/engagement/requests/{id}/interest` | interes | me interesa |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Cuenta sin perfil en modo Proveedor ve «Crea tu perfil para ver oportunidades».
- [ ] AC-002 → FR-002: Con un pedido pendiente, la sección «Pedidos por responder» aparece antes que «Solicitudes para ti».
- [ ] AC-003 → FR-003: Tocar «Me interesa» cambia a «Interés enviado»; tocarlo de nuevo lo retira.
- [ ] AC-004 → FR-003: Solicitud con `pickedProvider` distinto del perfil propio no ofrece interés.
- [ ] AC-005 → FR-004: Con «Urgentes (hoy)» activo solo aparecen solicitudes `today` y el botón de filtros muestra 1.
- [ ] AC-006 → FR-005: Perfil al 31 % muestra «Tu perfil está al 31 %» y el siguiente pendiente.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- `pickedProvider` se compara con el id del perfil propio; si la API cambia el identificador, «Te eligió» no se muestra.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
