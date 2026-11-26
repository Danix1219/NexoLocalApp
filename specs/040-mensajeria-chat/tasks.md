# Tareas — 040-mensajeria-chat

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/messages/inbox_page.dart`, `lib/features/messages/chat_page.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. La bandeja muestra no leídos por conversación y el filtro «Sin leer · N». Acepta: AC-001 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. El historial llega del más nuevo al más viejo y se muestra en orden cronológico con separadores Hoy/Ayer/fecha. Acepta: AC-002 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Enviar texto o foto; el mensaje propio muestra hora y palomita de leído. Acepta: AC-003 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Bloquear pide confirmación (y avisa si hay pedido activo); bloqueada, no se puede escribir y se ofrece desbloquear. Acepta: AC-004 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Al abrir el chat se marca leído hasta el último mensaje de la contraparte. Acepta: AC-005 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_messages_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_mensajes_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.

Correccion 2026-11-17: microfono visible con preparacion E2EE, estados con texto/color y recepcion desde bandeja sin lectura automatica. Evidencia local y limites: docs/chat-privado-e2ee.md. Recorrido con dos telefonos pendiente de confirmar tras instalar APK actualizado.

## Correccion 2026-11-17: aprovisionamiento automatico

- [ ] Registro automatico al restaurar sesion, cifrado predeterminado en la app y retirada de activacion manual (FR-E2EE-AUTO). Estado: implementada; aceptación pendiente.
- [ ] Recuperacion exclusivamente de inicializacion vacia; preservacion de estado cifrado sin clave (NFR-E2EE-RECOVERY). Estado: implementada; aceptación pendiente.
- [ ] Registro real en Xiaomi y Motorola y confirmacion del usuario de fotos/voz enviadas (AC-E2EE-AUTO). Estado: implementada; aceptación pendiente.
- [ ] Validacion del aspecto final de foto/logo de notificacion tras recibir un push nuevo en ambos Android.

- [ ] FR-PUSH-AVATAR: reintentar avatar ausente/fallido y actualizar shortcut existente; politica HTTPS por salto, HTTP local solo debug. Estado: implementada; aceptación pendiente.
- [ ] AC-PUSH-AVATAR: confirmar foto real en push nuevo con Xiaomi y Motorola reconectados.

- [ ] FR-PRIVATE-HISTORY: descifrado secuencial y aislamiento por mensaje no disponible, preservando ciphertext y nuevas operaciones. Estado: implementada; aceptación pendiente.
- [ ] AC-PRIVATE-HISTORY (dobles): http_mensajes_test.dart, siete pruebas aprobadas; caso nuevo conserva mensaje reciente tras sobre de otro dispositivo y descifrado fallido. Estado: implementada; aceptación pendiente.
- [ ] AC-PRIVATE-HISTORY (Android): confirmar apertura y nuevos envios tras reinstalar la correccion.

- [ ] FR-PRIVATE-HISTORY-LOCAL: recuperar copia propia original y comparar sobres cacheados por campos, no orden JSON. Pruebas de reordenacion, alteracion y copia propia en privacidad_test.dart y http_mensajes_test.dart. Estado: implementada; aceptación pendiente.

### Incremento de experiencia del chat

- [ ] T-CHAT-040 (FR-CHAT-UX/AC-CHAT-UX): cola local por cuenta, estados honestos y conciliacion sin duplicados. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-CHAT-041 (FR-CHAT-MEDIA/AC-CHAT-UX): previsualizacion de fotos con texto y reproductor/grabador de voz. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-CHAT-042 (FR-CHAT-HISTORY/AC-CHAT-UX): historial inmediato desde cache cifrada, refresco sin skeleton de burbujas. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-CHAT-043 (NFR-CHAT-UX/AC-CHAT-UX): burbujas compactas, pruebas y recorrido real en Android. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada.

Validacion local del incremento UX: 75 pruebas aprobadas (diseno_maqueta, http_mensajes, privacidad, push_seguro y token_storage_isolation); flutter analyze sin incidencias; formato de 143 archivos sin cambios. T-CHAT-043 conserva pendiente la revision visual en dispositivo.

- [ ] T-CHAT-044 (FR-VOICE-LONG): audio sin corte temporal, bloques cifrados y regresion mayor a un minuto. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.

Evidencia FR-VOICE-LONG: audio WAV de 75 segundos con tres bloques cifrados recuperado exactamente; corrupcion y conversacion ajena rechazadas. 72 pruebas aprobadas del conjunto de diseno, enlaces, privacidad y HTTP de mensajes. Grabacion y reproduccion nativas prolongadas pendientes de recorrido humano.


### Correccion de pendientes 2026-11-19
T-CHAT-045 (FR-READ-RECONCILE/AC-READ-RECONCILE): implementado y probado localmente con widget de historial largo y hueco antiguo. Recorrido fisico pendiente; no se declara aceptacion humana.

### Gestion de chat 2026-11-19
T-CHAT-046 (FR-CHAT-MANAGE/AC-CHAT-MANAGE): implementar fondos, lista inversa y menu contextual propio con confirmacion de eliminacion, editor y errores explicitos. Pruebas locales y recorrido real pendientes.

Tema coordinado (FR/AC-CHAT-THEME): paleta por estilo aplicada a burbujas y audio; acceso en cabecera y opciones; comprobar contraste y selector en suite diseno_maqueta. Validacion fisica pendiente.

FR/AC-CHAT-ACTIONS: panel contextual implementado y validado (edicion vacia/sin cambios, guardar, cancelar, confirmacion de borrado). diseno_maqueta 53/53; analyze sin incidencias. Revision visual humana pendiente.

2026-11-21 FR/AC-ASRS: ChatLive consume negotiate del ticket; Azure usa negociacion, modo directo Redis permanece compatible. Reconecta con ticket nuevo y descarta inicios obsoletos al salir. API conserva autoridad de grupos e identidad y no entrega claves Azure al cliente. Evidencia: 10/10 http_mensajes_test con dobles; flutter analyze sin incidencias. Validacion fisica pendiente. Contrato: repositorio API specs/endpoints/10-mensajes/ws-hubs-chat.md.

Auditoria fisica UI 2026-11-21: conservar contratos; corregir distribucion del encabezado de busqueda con ubicacion en segunda fila y ayuda de publicar debajo de agregar fotos. Regresion de encabezado en ancho reducido y escala de texto. Recorrido Motorola real; Xiaomi limitado por espejo congelado. Reporte en docs/qa/auditoria-dispositivos-2026-11-21.md.

2026-11-21 Ajustes de auditoria: FR/AC-UI-AUDIT: solicitud sin identidad publica muestra etiqueta honesta y avatar neutro, metadatos sin separadores vacios; compartir perfil abre acciones separadas de compartir/copiar/QR; bandeja distribuye nombre y fecha con ancho acotado y contador adaptable. Ver docs/qa/auditoria-dispositivos-2026-11-21.md. No inventar datos ni modificar contratos. Verificar regresiones widgets y analisis.


### UX de acciones - 2026-11-21
Implementacion local: menu compacto, edicion en compositor y confirmacion de borrado. Regresion en diseno_maqueta_test.dart para restaurar borrador al cancelar. Aceptacion visual humana en dispositivo pendiente.


T-CHAT-047 (FR-CHAT-REDESIGN y ampliaciones FR-CHAT-ACTIONS/FR-CHAT-THEME): bandeja, chat, acciones y personalizacion con regresiones en diseno_maqueta_test.dart. Revision visual en dispositivo pendiente.

- [ ] T-CHAT-048 (FR-INBOX-TIME, FR-CHAT-THEME): implementado y revisado con capturas generadas en prueba. Revisión en dispositivo pendiente. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.

- [ ] T-CHAT-049 (FR-VOICE-GESTURE, FR-CHAT-ACTIONS): `voice_composer.dart`, `chat_message_actions.dart`; pruebas con dobles. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-CHAT-050A Recorrido real de voz (permiso, enviar, cancelar, bloquear, reproducir) en Android.

- [ ] T-CHAT-051A (FR-CHAT-PREFETCH): `chat_experience.dart`, `encrypted_chat_transport.dart`; prueba en `privacidad_test.dart`. Estado: implementada; aceptación pendiente.
- [ ] T-CHAT-051B Comprobar en dos teléfonos, también sin conexión.
