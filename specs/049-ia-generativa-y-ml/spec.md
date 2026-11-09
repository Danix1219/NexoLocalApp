# 049-IA-GENERATIVA-Y-ML — IA generativa (borrador editable) y ML en el teléfono (categoría por foto)

Versión: 0.6.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-049-ia-generativa-y-ml`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [013-inteligencia](../013-inteligencia/spec.md), [005-contenido-seguro](../005-contenido-seguro/spec.md), [009-solicitudes](../009-solicitudes/spec.md).

Fuente visual: 7.10 Publicar (solicitud y trabajo); requisito 16 del profesor: «al menos una función de ML y de IA generativa». Actor: Cliente que publica una solicitud o prestador que publica un trabajo. Precondición: Sesión iniciada; para el borrador, servicio elegido y al menos 10 caracteres escritos.

Código: `src/mobile/nexo_app/` — `lib/features/intelligence/category_suggester.dart`, `lib/features/intelligence/ml_kit_suggester.dart`, `lib/features/intelligence/assist_sheet.dart`, `lib/features/intelligence/redact.dart`, `lib/features/publish/publish_page.dart`, `lib/data/http_nexo_api.dart`, `lib/data/nexo_api.dart`, `lib/data/fake/fake_nexo_api.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Dos funciones distintas y evaluables: un modelo de visión en el teléfono sugiere la categoría a partir de la foto (ML) y el backend genera un borrador editable del texto (IA generativa). Ninguna publica sola; la persona decide.

## 3. Alcance / Fuera de alcance

Incluye:

- ML: ML Kit Image Labeling (modelo base en el teléfono); suma de confianza por categoría, abstención por debajo de 55 % o con margen menor a 15 puntos; aviso «Por la foto parece… (n %)» con Usar/Ignorar.
- IA generativa: «Ayúdame a redactar» → `POST /v1/assist/draft` (EP-082) con `kind`, `categoryId`, `userText`, `lengthLimit`; hoja con el borrador editable, «Usar este texto» o «Seguir escribiendo yo».
- Antes de la red se quitan teléfono, correo, enlaces y domicilio del texto.
- Asistente caído o moderación: mensaje claro y edición manual; en release no se generan plantillas.

Fuera de alcance:

- Entrenamiento de un modelo propio y su evaluación con datos de Nexo (deuda de spec 013).
- Proveedor del modelo generativo y su prompt: los define el backend (nv-13).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Al agregar la foto de una solicitud sin categoría elegida, el modelo de visión del teléfono sugiere una categoría con su porcentaje de confianza; la persona la usa o la ignora.
- FR-002: El modelo se abstiene si la mejor categoría junta menos de 55 % o si la segunda está a menos de 15 puntos; también si el modelo falla.
- FR-003: «Ayúdame a redactar» pide a EP-082 un borrador y lo muestra editable; el texto solo pasa al campo con «Usar este texto» y se publica con el botón de siempre.
- FR-004: El texto que se envía al asistente no lleva teléfonos, correos, enlaces ni domicilios.
- FR-005: Si el asistente no responde (sin señal, 404, 5xx o `assist.unavailable`) se informa y la persona sigue escribiendo; en release nunca se inventa un borrador.
- FR-006: Si la moderación rechaza el texto (`content.inappropriate`) se muestra un mensaje claro y no se publica.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| FR-006 | T-015 | AC-006 | `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/ia_sin_datos_personales_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/assist/draft` | asistente | borrador generativo editable (EP-082, por formalizar) |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Etiquetas Sink 0.72 + Tap 0.41 sugieren Plomería; «Usar» llena el servicio.
- [ ] AC-002 → FR-002: Etiquetas Lamp 0.70 y Wood 0.65 no sugieren nada; etiquetas sin relación tampoco.
- [ ] AC-003 → FR-003: `POST /v1/assist/draft` lleva `kind`, `categoryId`, `userText`, `lengthLimit` y Bearer; el borrador aparece editable y no se publica solo.
- [ ] AC-004 → FR-004: «Llámame al 771 123 4567, Calle Hidalgo #45» se envía como «Llámame al [teléfono], [domicilio]».
- [ ] AC-005 → FR-005: Sin simulación (release) la maqueta responde `assist.unavailable` y la hoja muestra «El asistente no está disponible…».
- [ ] AC-006 → FR-006: Con 403 `content.inappropriate` la hoja muestra que el texto no cumple las reglas.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El modelo base de ML Kit no está entrenado con fotos de servicios de Nexo: falta medir macro-F1, abstención y latencia con un conjunto de evaluación propio (spec 013, AC-001/AC-090).
- EP-082 sigue «por formalizar» en el inventario de la API; si el backend cambia la forma, se ajusta `assistDraft`.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.6.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
