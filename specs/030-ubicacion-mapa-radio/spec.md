# 030-UBICACION-MAPA-RADIO — Ubicación de búsqueda y zona: selector de mapa, radio y GPS

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-030-ubicacion-mapa-radio`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [007-descubrimiento](../007-descubrimiento/spec.md), [023-privacidad-permisos-enlaces](../023-privacidad-permisos-enlaces/spec.md), [006-perfiles](../006-perfiles/spec.md).

Fuente visual: Selector de mapa (`pickerOpen`, `zoneSheet`, `miniMap`) de la maqueta. Actor: Cliente (dónde busca), prestador (zona o local) y cliente al pedir (domicilio). Precondición: Permiso de ubicación opcional; mapa con mosaicos ArcGIS.

Código: `src/mobile/nexo_app/` — `lib/features/location/location_picker_page.dart`, `lib/core/widgets/map_view.dart`, `lib/features/shell/top_bar.dart`, `lib/data/api_provider.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Elegir un punto moviendo el mapa bajo un alfiler fijo, con radio de 2, 5, 10 o 20 km y opción de usar el GPS, sin publicar el punto exacto.

## 3. Alcance / Fuera de alcance

Incluye:

- Pantalla de selector con mapa, alfiler fijo, radio y «Usar mi ubicación».
- Chip de ubicación en Inicio/Buscar y caja «Tu ubicación» en Cuenta.
- Mini mapas de solo lectura (perfil, pedido, cuenta).
- Persistir la ubicación de búsqueda en el backend.

Fuera de alcance:

- Geocodificación de direcciones escritas (pendiente de proveedor).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: El selector devuelve punto, radio y origen (`map` o `gps`); el radio solo se pide donde aplica.
- FR-002: «Usar mi ubicación» pide permiso; si se niega o el GPS está apagado, avisa y deja mover el mapa.
- FR-003: Al confirmar la ubicación de búsqueda se guarda con `PUT /me/location` y Inicio/Buscar se recargan con la zona nueva.
- FR-004: Los mini mapas de pedido pendiente muestran zona aproximada (círculo), no un alfiler exacto.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_discovery_test.dart`, `test/integration/http_descubrimiento_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_discovery_test.dart`, `test/integration/http_descubrimiento_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_discovery_test.dart`, `test/integration/http_descubrimiento_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_discovery_test.dart`, `test/integration/http_descubrimiento_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| PUT | `/v1/discovery/me/location` | descubrimiento | guardar ubicación de búsqueda |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Elegir 5 km y confirmar devuelve `radiusKm=5` y `source=map`; en domicilio no aparece el selector de radio.
- [ ] AC-002 → FR-002: Con el permiso denegado aparece «Sin permiso de ubicación. Mueve el mapa a tu zona.» y el selector sigue usable.
- [ ] AC-003 → FR-003: Cambiar a Jardines muestra «Resultados adaptados a Jardines» y el chip cambia.
- [ ] AC-004 → FR-004: El prestador ve un pedido pendiente con círculo de ~600 m y sin dirección.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El GPS en interiores puede tardar; hay límite de 15 s.
- Mosaicos ArcGIS requieren internet; sin señal el mapa queda gris pero la app no falla.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
