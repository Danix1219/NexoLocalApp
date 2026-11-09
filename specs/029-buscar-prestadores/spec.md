# 029-BUSCAR-PRESTADORES — Buscar prestadores: texto, sugerencias, filtros, lista y mapa

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-029-buscar-prestadores`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [007-descubrimiento](../007-descubrimiento/spec.md), [018-catalogo-seleccion](../018-catalogo-seleccion/spec.md).

Fuente visual: 7.6 Buscar — solicitante (`searchTop`, `filterSheet`, `activeChips`, `provRow`, `provMapHTML`). Actor: Cliente o visitante. Precondición: Ubicación de búsqueda definida.

Código: `src/mobile/nexo_app/` — `lib/features/search/search_page.dart`, `lib/features/search/filters.dart`, `lib/core/widgets/map_view.dart`, `lib/data/models.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Encontrar prestadores que atienden la zona por palabra, categoría y filtros, verlos en lista o mapa y pasar a comparar o contactar.

## 3. Alcance / Fuera de alcance

Incluye:

- Campo de búsqueda con sugerencias (categoría, especialidad, término) con espera de 280 ms.
- Hoja de filtros: servicio, abierto ahora, visita sin costo, con precios, urgencias, atención, orden.
- Chips de filtros activos con quitar uno a uno.
- Aros de categoría cuando no hay texto ni categoría.
- Lista de resultados, aviso fuera de zona y ampliar zona; vista de mapa con puntos.

Fuera de alcance:

- Búsqueda de solicitudes del prestador (spec 028).
- Perfil completo (spec 031).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Escribir 2 o más letras muestra sugerencias; elegir una categoría la aplica como filtro y limpia el texto.
- FR-002: Los filtros se envían solo si están activos (`open`, `free`, `prices`, `urgent`, `attention`, `sort`, `cat`) y el botón muestra cuántos hay.
- FR-003: Si nadie atiende la zona con esos filtros, se muestra el aviso del servidor y los más cercanos; se puede ampliar la zona.
- FR-004: La vista Mapa muestra el radio, los puntos abiertos/cerrados y una tarjeta al tocar uno que lleva al perfil.
- FR-005: Sin resultados se ofrece quitar filtros o cambiar ubicación.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_discovery_test.dart`, `test/unit/filters_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_discovery_test.dart`, `test/unit/filters_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_discovery_test.dart`, `test/unit/filters_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_discovery_test.dart`, `test/unit/filters_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/fake_discovery_test.dart`, `test/unit/filters_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/search/providers` | descubrimiento | resultados |
| GET | `/v1/discovery/search/suggest` | descubrimiento | sugerencias |
| GET | `/v1/discovery/map/nearby?kind=providers` | descubrimiento | mapa |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Escribir «plom» sugiere Plomería; elegirla deja `cat=plomeria` y el campo vacío.
- [ ] AC-002 → FR-002: Con «Abierto ahora» y «Más cerca», la consulta lleva `open=true&sort=near` y no lleva `free`.
- [ ] AC-003 → FR-003: Respuesta con `outOfZone=true` muestra el aviso en ámbar arriba de la lista.
- [ ] AC-004 → FR-004: Tocar un punto muestra su nombre y categoría; tocar la tarjeta abre `/provider/{id}`.
- [ ] AC-005 → FR-005: Búsqueda sin coincidencias con filtros muestra «Quitar filtros» y al tocarlo se limpian.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Las sugerencias dependen de `/search/suggest`; mientras no exista, el modo auto usa el catálogo local.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
