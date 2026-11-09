# 042-GUARDADOS-RECOMENDACIONES — Guardados y recomendaciones

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-042-guardados-recomendaciones`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [019-guardados-indicadores](../019-guardados-indicadores/spec.md), [008-comunidad](../008-comunidad/spec.md).

Fuente visual: 7.12 Guardados (`V.saved`) y acciones de guardar/recomendar. Actor: Persona con sesión. Precondición: Sesión.

Código: `src/mobile/nexo_app/` — `lib/features/account/saved_page.dart`, `lib/features/common/actions.dart`, `lib/features/common/cards.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Volver a prestadores, trabajos y solicitudes de interés y apoyar trabajos con una recomendación.

## 3. Alcance / Fuera de alcance

Incluye:

- Guardar/quitar prestador, trabajo y solicitud con conteos.
- Página Guardados por tipo; elementos no disponibles con «Quitar».
- Recomendar/quitar recomendación de un trabajo.

Fuera de alcance:

- Colecciones o carpetas.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Guardar y quitar actualizan el ícono y el conteo de Cuenta.
- FR-002: Guardados agrupa Prestadores, Trabajos y Solicitudes; lo que ya no existe se muestra como no disponible con «Quitar».
- FR-003: Recomendar devuelve el nuevo total del servidor y lo muestra.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/saved` | guardados | lista |
| POST/DELETE | `/v1/discovery/saved/{kind}/{id}` | guardados | guardar o quitar |
| POST/DELETE | `/v1/discovery/works/{id}/recommend` | trabajos | recomendar |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Guardar un prestador sube «Guardados · 1» en Cuenta.
- [ ] AC-002 → FR-002: Trabajo con `available=false` muestra «Este trabajo ya no está disponible».
- [ ] AC-003 → FR-003: Recomendar con respuesta `recs=13` muestra «13 recomendaciones».

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Sin riesgos propios además de los transversales de 045–047.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
