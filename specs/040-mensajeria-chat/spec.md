# 040-MENSAJERIA-CHAT — Mensajes: bandeja y chat

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-040-mensajeria-chat`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [011-mensajeria](../011-mensajeria/spec.md), [025-contacto-consentimiento](../025-contacto-consentimiento/spec.md).

Fuente visual: 7.16 Mensajes (`V.inbox`, `V.chat`, `chatbar`, respuestas rápidas). Actor: Cliente o prestador. Precondición: Sesión; conversación abierta desde contacto, pedido o solicitud.

Código: `src/mobile/nexo_app/` — `lib/features/messages/inbox_page.dart`, `lib/features/messages/chat_page.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Conversar para acordar precio, fecha y lugar, con el estado del pedido visible y control de bloqueo.

## 3. Alcance / Fuera de alcance

Incluye:

- Bandeja por rol con filtro Todos/Sin leer, avatar, última vista previa, hora, estado del pedido y no leídos.
- Chat con burbujas, separadores de día, mensajes de sistema que llevan al pedido, fotos, respuestas rápidas.
- Barra superior: estado del pedido o «Pedir servicio».
- Menú: ver perfil, ver pedido, reportar, bloquear/desbloquear.
- Consulta cada 4 s y marcado de leído.

Fuera de alcance:

- Tiempo real con SignalR (deuda, spec 011).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: La bandeja muestra no leídos por conversación y el filtro «Sin leer · N».
- FR-002: El historial llega del más nuevo al más viejo y se muestra en orden cronológico con separadores Hoy/Ayer/fecha.
- FR-003: Enviar texto o foto; el mensaje propio muestra hora y palomita de leído.
- FR-004: Bloquear pide confirmación (y avisa si hay pedido activo); bloqueada, no se puede escribir y se ofrece desbloquear.
- FR-005: Al abrir el chat se marca leído hasta el último mensaje de la contraparte.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/engagement/conversations` | mensajes | bandeja |
| GET | `/v1/engagement/conversations/{id}/messages` | mensajes | historial |
| POST | `/v1/engagement/conversations/{id}/messages` | mensajes | enviar |
| POST | `/v1/engagement/conversations/{id}/read` | mensajes | leído |
| POST | `/v1/engagement/conversations/{id}/block` | mensajes | bloquear |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Con 2 conversaciones sin leer el chip dice «Sin leer · 2».
- [ ] AC-002 → FR-002: Mensajes m2 (nuevo) y m1 (viejo) se muestran m1 arriba y m2 abajo.
- [ ] AC-003 → FR-003: Enviar «hola» manda `{kind:'text', text:'hola'}` y limpia el campo.
- [ ] AC-004 → FR-004: Conversación bloqueada muestra «Bloqueaste a …» y oculta el campo de texto.
- [ ] AC-005 → FR-005: Abrir un chat con 1 no leído envía `upToMessageId` del último y el globo baja.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El sondeo cada 4 s se detiene al salir del chat (Timer cancelado en dispose).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |


## Revisi?n UX y seguridad (2026-11-16)

Enviado y le?do se distinguen mediante iconos y etiquetas accesibles. La lectura se confirma solo despu?s del ?xito HTTP con la conversaci?n visible y siguiendo los mensajes recientes; se reintenta al fallar. La recarga conserva la posici?n al consultar historial y evita peticiones superpuestas. Enviar conserva cambios al borrador realizados durante una petici?n y evita env?os simult?neos. Entregado requiere un acuse del dispositivo receptor: SignalR enviado no acredita entrega. Audio y cifrado E2EE requieren contratos, gesti?n de claves por dispositivo y decisi?n expl?cita sobre la sustituci?n de moderaci?n del servidor. No se declara E2EE con los contratos actuales.

Decisi?n confirmada 2026-11-16: priorizar E2EE y adaptar moderaci?n. Dise?o y criterios pendientes de implementaci?n: [chat privado](../../docs/chat-privado-e2ee.md). Los contratos actuales siguen sin E2EE.

Actualizacion 2026-11-16: contratos y cliente privado implementados localmente tras aprobacion; activacion de produccion pendiente. Fotos y voz cifradas, acuse de entrega y verificacion de identidad documentados en [chat privado](../../docs/chat-privado-e2ee.md). La evidencia y limitaciones estan separadas de la aceptacion en dispositivos.

### Incremento 2026-11-17: seguridad automatica

- FR-E2EE-AUTO: provisionar claves publicas al restaurar/iniciar sesion y habilitar la conversacion automaticamente cuando ambos dispositivos dispongan de claves; no pedir activacion manual. El permiso nativo de microfono se solicita al grabar.
- NFR-E2EE-RECOVERY: recuperar un archivo de inicializacion vacio sin clave; rechazar recuperacion automatica si existe estado cifrado. No borrar historial, claves ni degradar a texto sin cifrar.
- AC-E2EE-AUTO: ambos Android registran claves sin intervencion y permiten fotos/voz; registros locales security ready y confirmacion del usuario de envio recibida el 2026-11-17. No acredita despliegue productivo.

- FR-PUSH-AVATAR: mostrar la foto real del contacto cuando la API la proporciona y reintentar cuando su descarga falla; HTTP local solo en debug, HTTPS obligatorio en release y en cada redireccion.
- AC-PUSH-AVATAR: prueba automatizada de recuperacion de avatar y politica de transporte; verificacion visual en ambos telefonos pendiente de reconexion ADB.

### Recuperacion de historial privado 2026-11-17

- FR-PRIVATE-HISTORY: un mensaje privado no disponible para este dispositivo no bloquea el resto de la conversacion; mostrar un estado explicito por mensaje y conservar orden, identidad y posibilidad de nuevos envios. No resetear claves ni degradar cifrado.
- AC-PRIVATE-HISTORY: historial mixto con mensaje no descifrable conserva mensajes legibles; acuse acumulativo de lectura no atraviesa mensajes privados no disponibles. Fallos globales de red/provisionamiento siguen siendo errores reales.

- FR-PRIVATE-HISTORY-LOCAL: recuperar mensaje propio desde copia local cifrada antes de intentar sobre de otro dispositivo; aceptar campos de sobre reordenados solo cuando valores y conversacion coinciden exactamente. Rechazar contenido o metadatos alterados.

### Experiencia de conversacion y medios (2026-11-17)

- FR-CHAT-UX: insercion inmediata de mensajes locales, cola ordenada con estado pendiente/error/reintento y conciliacion por ID confirmado. Nunca inferir entrega/lectura de una previsualizacion local.
- FR-CHAT-MEDIA: fotos con previsualizacion y pie de foto opcional dentro del contenido E2EE; renderizado automatico al hacerse visibles, ampliacion y cache solo en memoria. Audio con controles, duracion y progreso; grabacion con detener, escuchar, descartar y enviar.
- FR-CHAT-HISTORY: mostrar historial previamente disponible desde memoria o vault cifrado mientras se actualiza; sustituir skeleton de burbujas por un estado discreto de primera sincronizacion. Sin texto privado en cache HTTP o archivos de medios descifrados.
- NFR-CHAT-UX: burbujas acotadas al ancho disponible, texto largo ajustado, hora y acuse compactos; accesibilidad y ampliacion de fuente sin desbordes. Aislar cache/cola por cuenta y borrar bytes en memoria al cerrar sesion.
- AC-CHAT-UX: pruebas de cola inmediata, conciliacion/reintento, aislamiento, caption cifrado y composicion de medios; Android para grabar, escuchar, foto con texto, apertura repetida y textos largos. Latencia de red no se declara instantanea: solo la representacion local es inmediata.

- FR-VOICE-LONG: retirar el corte fijo de un minuto; audio largo se envia en bloques cifrados autenticados, conservando duracion real y controles de grabacion. No introducir limite de tiempo en la interfaz; errores de recursos se comunican sin perder silenciosamente la grabacion.

### Correccion lectura 2026-11-19
FR-READ-RECONCILE: mensajes antiguos no disponibles no bloquean lectura de posteriores visibles; abrir historial guardado situa en recientes. Confirmacion HTTP refresca contadores independientemente de notificacion local. AC-READ-RECONCILE: regresion con hueco antiguo y mensaje nuevo; nunca inventar lectura de un mensaje no disponible.

### Gestion de chat 2026-11-19
FR-CHAT-MANAGE: abrir historial en mensajes recientes sin desplazamiento inicial; fondos locales por cuenta/conversacion; editar texto propio cifrado y eliminar mensajes propios para ambos con marca persistente. AC-CHAT-MANAGE: propiedad, confirmacion, errores sin exito ficticio, etiquetas Editado/Eliminado, fondo persistente y posicion inicial al final.

### Tema coordinado del chat 2026-11-19
FR-CHAT-THEME: cada fondo aplica paleta legible a burbujas propias, recibidas, audio y metadatos; acceso directo con icono de paleta en cabecera y alternativa en opciones. AC-CHAT-THEME: cinco paletas diferenciadas, persistencia existente por cuenta/conversacion y previsualizacion coordinada.

FR-CHAT-ACTIONS: editar/eliminar desde panel contextual tematizado con vista previa, teclado adaptativo, validacion del texto y confirmacion explicita de eliminacion; cancelar conserva mensaje y borrador. AC-CHAT-ACTIONS: no dialogos genericos; guardar vacio/sin cambios deshabilitado; eliminar requiere segunda accion y conserva aviso de copias.

FR/AC-ASRS (2026-11-21): consumir indicador negotiate del ticket API. Azure usa negociacion y redireccion autorizada; Redis directo conserva skipNegotiation. Sin secretos Azure en Flutter. Cancelar inicio en curso al salir y renovar ticket en reconexion.


### Ajuste UX 2026-11-21 - acciones de mensajes
Edicion contextual dentro del compositor con vista previa del original, cancelar sin perder borrador y guardar sin reenviar ni duplicar. Eliminar requiere confirmacion explicita en hoja compacta con alcance para todos. Mantener errores recuperables, permisos y marcador editado/eliminado existentes. Aceptacion: cancelar restaura borrador; fallo conserva texto; no enviar multimedia mientras se edita.

### Rediseño de mensajes 2026-11-25
FR-CHAT-REDESIGN: bandeja con tarjetas por conversación, estado de pedido como etiqueta y mensaje propio para búsqueda sin resultados; chat con separadores de día en etiqueta, agrupación de mensajes consecutivos del mismo autor (menos de 5 min), botón para volver a lo reciente y compositor que alterna nota de voz/enviar. AC-CHAT-REDESIGN: sin cambios de contratos; sin desbordes a 320 px.

FR-CHAT-ACTIONS (ampliación): el panel muestra el mensaje como burbuja; permite copiar texto propio o recibido solo por acción explícita; editar/eliminar siguen limitados a mensajes propios cifrados. El mensaje en edición se resalta, atrás cancela la edición y aparece contador cerca del límite de 1000. La confirmación de eliminación conserva la segunda acción. AC: un mensaje recibido no ofrece editar ni eliminar.

FR-CHAT-THEME (ampliación): siete temas, patrón de fondo opcional, tamaño de letra (compacto, normal, grande) y forma de burbuja (redondeada, recta), con vista previa en vivo, restablecer y aplicar. Cerrar sin aplicar no cambia nada. Persistencia local por cuenta/conversación; los valores guardados antes (solo el tema) siguen válidos.

### Ajustes 2026-11-25 (segunda revisión)
FR-INBOX-TIME: la hora de cada conversación queda alineada al borde derecho de la tarjeta, sin importar el largo del nombre. AC: prueba de posición en `diseno_maqueta_test.dart`.
FR-CHAT-THEME (presentación): vista previa con hora, temas como miniaturas de conversación en cuadrícula, tamaño y forma con muestra visual y botones fijos. Mismo formato guardado.

### 2026-11-26 · notas de voz y menú de mensajes
FR-VOICE-GESTURE: grabar dentro de la barra del chat. Mantener el micrófono graba y soltar envía; deslizar a la izquierda cancela; deslizar arriba bloquea. Bloqueada: eliminar, pausar/continuar, escuchar y enviar. Menos de medio segundo se descarta con aviso. Atrás cancela. Al salir de la app queda en vista previa sin enviarse. Con lector de pantalla un toque inicia la grabación bloqueada. Sustituye la hoja de grabación anterior. Se conserva WAV 16 kHz y el envío cifrado existente.
FR-CHAT-ACTIONS (sustituye el panel inferior): menú flotante junto al mensaje, con fondo difuminado y las acciones Copiar, Editar y Eliminar según permisos; eliminar pide una confirmación centrada.
AC: gestos de voz y menú en `diseno_maqueta_test.dart` (micrófono simulado). Pendiente: gestos y audio reales en dos teléfonos.

### 2026-11-26 · adjuntos listos al abrir
FR-CHAT-PREFETCH (precisa FR-CHAT-MEDIA): al llegar un hilo se piden hasta 30 fotos y audios recientes, tres a la vez y sin descargas repetidas. En el teléfono se guardan **tal como viajan, cifrados**; se descifran solo en memoria. Cerrar sesión los borra. Los archivos descifrados siguen sin llegar a disco. La primera vez que el teléfono recibe un adjunto todavía depende de la red.
