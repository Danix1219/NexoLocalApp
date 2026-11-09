# 038-INTERES-E-INTERESADOS — «Me interesa», lista de interesados y cierre de solicitud

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-038-interes-e-interesados`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [021-interesados-candidatos](../021-interesados-candidatos/spec.md), [009-solicitudes](../009-solicitudes/spec.md).

Fuente visual: Interesados (`V.ints`), `intsum` y cierre de solicitud. Actor: Cliente dueño de la solicitud; prestador que se interesa. Precondición: Solicitud abierta.

Código: `src/mobile/nexo_app/` — `lib/features/requests/interested_page.dart`, `lib/features/common/actions.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Que el cliente compare a quienes se interesaron, les escriba o les pida el servicio, y cierre la solicitud con su resultado.

## 3. Alcance / Fuera de alcance

Incluye:

- Lista ordenable (mejor calificados, más recomendados, abiertos ahora).
- Por interesado: nota, estado, precio desde, visita, distancia; Comparar, Mensaje y Pedir servicio.
- Estado del pedido ya enviado.
- Cerrar: resuelto aquí, por otro lado o ya no lo necesito.

Fuera de alcance:

- Shortlist opcional (S08).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: El orden se pide al servidor (`sort=rate|recs|open`) y se refleja en los chips.
- FR-002: «Pedir servicio» solo está activo si `canOrder`; con pedido ya enviado se muestra su estado.
- FR-003: Cerrar la solicitud envía `outcome` y, si hubo elegido, `pickedProviderId`; luego deja de verse para prestadores.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_requests_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_requests_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_requests_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/engagement/requests/{id}/interested?sort=` | interes | interesados |
| POST | `/v1/discovery/requests/{id}/close` | solicitudes | cerrar |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Elegir «Más recomendados» consulta `sort=recs` y el primero es el de más recomendaciones.
- [ ] AC-002 → FR-002: Interesado con pedido pendiente muestra «Le enviaste un pedido · esperando respuesta» y Pedir deshabilitado.
- [ ] AC-003 → FR-003: «Lo resolví por otro lado» envía `outcome=solvedElsewhere` y la solicitud aparece como resuelta.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Orden y permisos son del servidor; el cliente no reordena localmente.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
