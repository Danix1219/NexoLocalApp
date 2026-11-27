# 035-PUBLICAR-SOLICITUD — Publicar «Busco un servicio»

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-035-publicar-solicitud`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [009-solicitudes](../009-solicitudes/spec.md), [005-contenido-seguro](../005-contenido-seguro/spec.md).

Fuente visual: 7.10 Publicar — pestaña «Busco un servicio» (`pubReq`, `optRow`). Actor: Cliente con sesión. Precondición: Modo cliente.

Código: `src/mobile/nexo_app/` — `lib/features/publish/publish_page.dart`, `lib/core/widgets/pick_image.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Publicar en pocas palabras lo que se necesita, con servicio, ubicación aproximada, urgencia y canal de contacto, y opcionalmente una foto.

## 3. Alcance / Fuera de alcance

Incluye:

- Texto 10–600 caracteres con título automático (primera frase, máx. 90).
- Filas: Servicio, Ubicación, ¿Para cuándo? (today, week, noRush), Te contactan por (chat, chatCall).
- Foto opcional con subida en 3 pasos.
- `Idempotency-Key` estable por borrador.

Fuera de alcance:

- Edición de una solicitud publicada.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: «Publicar» se habilita con servicio elegido y 10+ caracteres.
- FR-002: El título se genera de la primera frase; si es menor a 5 caracteres usa el texto completo.
- FR-003: La solicitud se envía con urgencia y contacto como slugs del contrato y la ubicación elegida o la de búsqueda.
- FR-004: Repetir «Publicar» por red lenta no duplica: la clave de idempotencia es la misma hasta publicar con éxito.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/discovery/requests` | solicitudes | publicar |
| POST | `/v1/discovery/uploads` | imagenes | foto |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Sin servicio elegido el botón queda deshabilitado aunque el texto tenga 50 caracteres.
- [ ] AC-002 → FR-002: «Fuga en el baño. Necesito…» genera el título «Fuga en el baño».
- [ ] AC-003 → FR-003: Elegir «Sin prisa» y «Chat y llamada» envía `urgency=noRush` y `contact=chatCall`.
- [ ] AC-004 → FR-004: Dos envíos del mismo borrador llevan el mismo `Idempotency-Key`.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- La moderación previa (spec 005) puede rechazar el texto; se muestra el `detail` de la API.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |

## 2026-11-26 · solicitudes propias y gestión de publicaciones
- FR-MYREQ-001: Tarjeta propia con categoría, zona, antigüedad, estado (Publicada, Con interesados, Con pedido, Resuelta), urgencia y fotos 16:10.
- FR-MYREQ-002: En Mi perfil, selector Solicitudes/Experiencias y filtros Todas, Activas y Resueltas con conteo.
- FR-PUBMGMT-001: Opciones con vista previa; edición con «Guardar cambios» fijo y errores visibles dentro de la hoja; eliminación con diálogo centrado, consecuencias, reintento y opción de conservar. Aplica también a trabajos (spec 036).
- FR-IMG-001: Mientras carga una foto se ve un fondo neutro (o las iniciales), nunca el color de la categoría.

## 2026-11-26 · publicar en una sola tarjeta
FR-COMPOSE-CARD: el formulario de solicitud y experiencia vive en una sola tarjeta: autor y alcance, texto, fotos en tira (hasta 6), opciones y un pie con lo que falta o «listo». Se conserva el botón «Publicar» de la barra superior. Parte del diseño original; sustituye en trabajos la versión de cuatro pasos. Sin cambios de contrato ni validaciones.

## 2026-11-26 · se restaura la vista de solicitudes
FR-MYREQ-001 y FR-MYREQ-002 quedan **sin efecto** a petición del usuario: tarjetas, pestañas y lista de solicitudes vuelven al diseño anterior. Se mantienen FR-PUBMGMT-001 y FR-IMG-001.

## 2026-11-26 · se restaura la experiencia de publicar
FR-COMPOSE-CARD (sustituye la versión anterior de hoy): se recupera el diseño original y su orden de elementos, en una sola tarjeta **sin divisiones ni franja de estado**. Mejoras: esquinas y sombra suaves, texto con alto según la pantalla y un botón de fotos compacto con contador. Las opciones de solicitud y experiencia continúan dentro de la misma tarjeta.

## 2026-11-26 · rediseño de opciones, edición y eliminación (FR-PUBMGMT-002)
La maqueta no define estas pantallas.
- Opciones: vista previa tal como se ve la publicación; «Editar» como acción principal y «Eliminar publicación» aparte.
- Edición: una sola tarjeta; fotos en tira con la primera marcada como portada; «Guardar cambios» se activa solo si hay cambios y el pie lo indica; salir con cambios pide confirmar y la hoja no se cierra arrastrando.
- Eliminación (sustituye el diálogo): hoja con la publicación, consecuencias en lista y confirmación **manteniendo presionado** 1.1 s; soltar cancela, incluso con un toque instantáneo. Con lector de pantalla, la activación confirma. El error se muestra dentro y permite reintentar.
