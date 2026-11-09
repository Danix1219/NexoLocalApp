# 033-COMPARAR-PRESTADORES — Comparar dos prestadores lado a lado

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-033-comparar-prestadores`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [007-descubrimiento](../007-descubrimiento/spec.md).

Fuente visual: Barra `cmpBar` y vista Comparar de la maqueta. Actor: Cliente con sesión. Precondición: Dos prestadores elegidos desde feed, búsqueda o interesados.

Código: `src/mobile/nexo_app/` — `lib/features/provider/compare_page.dart`, `lib/features/common/cards.dart`, `lib/data/api_provider.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Elegir con datos comparables (atención, estado, distancia, precio desde, visita, calificación, recomendaciones, respuesta, garantía, teléfono, actualización) y contactar desde ahí.

## 3. Alcance / Fuera de alcance

Incluye:

- Selección máxima de 2 con barra flotante.
- Tabla con el mejor de cada fila resaltado.
- Contactar a cualquiera de los dos y limpiar la selección.

Fuera de alcance:

- Comparar más de dos.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: La barra de comparar aparece con 1 o 2 elegidos y solo habilita «Comparar» con 2.
- FR-002: La tabla resalta en verde el valor que favorece (índice `best` de la API) y en gris lo no publicado.
- FR-003: «Limpiar» vacía la selección y regresa.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_discovery_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_discovery_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_discovery_test.dart`, `test/integration/http_perfil_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/providers/compare?ids=a,b` | perfil | filas de comparación |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con un elegido el botón Comparar está deshabilitado y dice «Elige 1 más para comparar».
- [ ] AC-002 → FR-002: Fila Recomiendan con 31 vs 22 resalta la primera columna.
- [ ] AC-003 → FR-003: Tras «Limpiar», la barra desaparece en Inicio y Buscar.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Si la API no envía `best`, no se resalta nada (no se calcula en el cliente para no contradecir al servidor).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
