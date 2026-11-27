# 036-PUBLICAR-TRABAJO — Publicar un trabajo realizado (prestador)

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-036-publicar-trabajo`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [008-comunidad](../008-comunidad/spec.md), [005-contenido-seguro](../005-contenido-seguro/spec.md).

Fuente visual: 7.10 Publicar — vista del prestador (`pubWork`). Actor: Prestador con perfil. Precondición: Modo prestador.

Código: `src/mobile/nexo_app/` — `lib/features/publish/publish_page.dart`, `lib/data/http_nexo_api.dart`, `lib/core/widgets/pick_image.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Mostrar trabajos hechos con fotos para ganar confianza y aparecer en el feed de su zona.

## 3. Alcance / Fuera de alcance

Incluye:

- Categoría entre las del perfil, texto 20–1000, etiqueta opcional, hasta 6 fotos.
- Subida de fotos: ticket, PUT a URL firmada sin Bearer y confirmación.
- Tras publicar: aparece en Mi perfil y en el feed.

Fuera de alcance:

- Etiquetar clientes en el trabajo.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: «Publicar» se habilita con 20+ caracteres e indica cuántos faltan.
- FR-002: Las fotos se reducen a 1600 px y se suben antes de crear el trabajo; el trabajo lleva los `uploadId`.
- FR-003: La subida a la URL firmada nunca lleva el Bearer de Nexo.
- FR-004: El trabajo se envía con la ubicación del perfil y aparece en Mi perfil.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| FR-004 | T-013 | AC-004 | `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/cabeceras_y_subidas_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |
| FR-005 | T-050, T-051 | Aceptación pendiente | Evidencia en la tarea y la bitácora |
| FR-006 | T-050, T-051 | Aceptación pendiente | Evidencia en la tarea y la bitácora |
| FR-007 | T-050, T-051 | Aceptación pendiente | Evidencia en la tarea y la bitácora |
| FR-008 | T-050, T-051 | Aceptación pendiente | Evidencia en la tarea y la bitácora |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/discovery/works` | trabajos | publicar |
| POST | `/v1/discovery/uploads` | imagenes | ticket |
| PUT | `{uploadUrl}` | imagenes | subida directa |
| POST | `/v1/discovery/uploads/{id}/complete` | imagenes | confirmar |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con 12 caracteres se lee «Escribe 8 caracteres más» y el botón está deshabilitado.
- [ ] AC-002 → FR-002: Con 2 fotos se hacen 2 tickets y `imageUploadIds` lleva 2 ids.
- [ ] AC-003 → FR-003: La petición PUT al almacenamiento no tiene header Authorization.
- [ ] AC-004 → FR-004: Tras publicar se abre Mi perfil con el trabajo nuevo arriba.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Si la URL firmada vence durante una subida lenta, se reporta error y se puede reintentar.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |

## Incremento 2026-11-25 · composición por pasos del prestador

- FR-005: Publicar un trabajo se organiza en identidad y cuatro pasos (servicio, descripción, fotos, etiqueta), cada uno con indicador de completado.
- FR-006: Barra inferior fija con lo que falta y el botón «Publicar»; mismas reglas de habilitación (20+ caracteres y ubicación).
- FR-007: Fotos en cuadrícula de 3 columnas, la primera marcada como portada; sin fotos la zona para agregar ocupa el ancho completo.
- FR-008: Etiquetas sugeridas de un toque, además del texto libre (máx. 40). Sin cambios de contrato.

## 2026-11-26 · publicar en una sola tarjeta
FR-COMPOSE-CARD: el formulario de trabajo vive en una sola tarjeta: autor y alcance, texto, fotos en tira (hasta 6), opciones y un pie con lo que falta o «listo». Se conserva el botón «Publicar» de la barra superior. Parte del diseño original; sustituye en trabajos la versión de cuatro pasos. Sin cambios de contrato ni validaciones.

## 2026-11-26 · se restaura la experiencia de publicar
FR-COMPOSE-CARD (sustituye la versión anterior de hoy): se recupera el diseño original y su orden de elementos, en una sola tarjeta **sin divisiones ni franja de estado**. Mejoras: esquinas y sombra suaves, texto con alto según la pantalla y un botón de fotos compacto con contador. Las opciones de solicitud y experiencia continúan dentro de la misma tarjeta.

## 2026-11-26 · rediseño de opciones, edición y eliminación (FR-PUBMGMT-002)
La maqueta no define estas pantallas.
- Opciones: vista previa tal como se ve la publicación; «Editar» como acción principal y «Eliminar publicación» aparte.
- Edición: una sola tarjeta; fotos en tira con la primera marcada como portada; «Guardar cambios» se activa solo si hay cambios y el pie lo indica; salir con cambios pide confirmar y la hoja no se cierra arrastrando.
- Eliminación (sustituye el diálogo): hoja con la publicación, consecuencias en lista y confirmación **manteniendo presionado** 1.1 s; soltar cancela, incluso con un toque instantáneo. Con lector de pantalla, la activación confirma. El error se muestra dentro y permite reintentar.
