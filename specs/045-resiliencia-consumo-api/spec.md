# 045-RESILIENCIA-CONSUMO-API — Resiliencia del consumo: endpoints ausentes o sin señal sin error en pantalla

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-045-resiliencia-consumo-api`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [003-contratos-consumo](../003-contratos-consumo/spec.md), [016-sincronizacion-local](../016-sincronizacion-local/spec.md).

Fuente visual: Transversal (todas las pantallas que consumen API). Actor: Cualquier persona usando la app mientras el backend publica sus endpoints. Precondición: App con `API_MODE=auto` (de fábrica).

Código: `src/mobile/nexo_app/` — `lib/data/nexo_api.dart`, `lib/data/api_provider.dart`, `lib/data/http_nexo_api.dart`, `lib/data/fake/fake_nexo_api.dart`, `lib/features/shell/shell_page.dart`, `lib/app/env.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Que la app funcione completa aunque un endpoint todavía no exista, no responda o no haya señal, usando los datos de ejemplo de la maqueta, y que use el backend real en cuanto el endpoint aparece, sin cambiar código.

## 3. Alcance / Fuera de alcance

Incluye:

- Modos por grupo: `auto`, `live`, `fake` (`API_MODE`, `LIVE`, `FAKE`).
- Clasificación «no disponible»: sin red, tiempo agotado, 404/405/501/5xx sin código de Nexo, respuesta que no es JSON o forma inesperada.
- Espera de 60 s por grupo antes de reintentar; sin red marca todos los grupos de una vez.
- Errores de negocio (códigos de Nexo, 400, 401, 403, 409, 412) siempre se muestran.
- Aviso discreto en el shell mientras algún grupo usa ejemplo.

Fuera de alcance:

- Cola offline de escrituras y reconciliación (autoridad: spec 016).
- Login y registro: siempre reales.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: En modo `auto`, una llamada «no disponible» responde con los datos de ejemplo del mismo método, sin error en pantalla.
- FR-002: Un error de negocio con código de Nexo nunca se reemplaza por datos de ejemplo.
- FR-003: Tras 60 s se vuelve a intentar el backend; si responde, el grupo regresa a datos reales y el aviso desaparece.
- FR-004: Sin señal, todos los grupos en `auto` pasan a ejemplo a la vez para no esperar el tiempo de conexión en cada pantalla.
- FR-005: `LIVE` fuerza grupos al backend (sus errores se muestran) y `FAKE` los fuerza a la maqueta sin red.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001, AC-002 | `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart` |
| FR-002 | T-011 | AC-003 | `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart` |
| FR-003 | T-012 | AC-004 | `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart` |
| FR-004 | T-013 | AC-005 | `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart` |
| FR-005 | T-014 | AC-006 | `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| * | `Los 13 grupos de `docs/endpoints` excepto auth` | todos | consumo resiliente |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Feed con `GET /v1/discovery/feed` en 404 sin cuerpo devuelve trabajos de ejemplo y marca `descubrimiento` en ejemplo.
- [ ] AC-002 → FR-001: Feed que responde HTML con 200 devuelve trabajos de ejemplo.
- [ ] AC-003 → FR-002: Aceptar pedido con 412 `order.version_conflict` lanza el error y el grupo sigue en backend real.
- [ ] AC-004 → FR-003: Con el endpoint publicado, a los 61 s el feed devuelve el trabajo real y el aviso se oculta.
- [ ] AC-005 → FR-004: Con la red caída, una sola falla marca los 13 grupos y la siguiente pantalla no vuelve a llamar a la red.
- [ ] AC-006 → FR-005: `LIVE=all` con feed en 404 muestra el error; `API_MODE=fake` no hace ninguna llamada.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Mezclar datos reales y de ejemplo puede cruzar IDs (un pedido real con un prestador de ejemplo); el aviso lo hace visible.
- Escrituras en ejemplo no llegan al servidor; no sustituyen la cola offline de spec 016.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
