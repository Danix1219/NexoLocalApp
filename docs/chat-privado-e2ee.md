# Chat privado y experiencia de mensajeria

Estado: implementacion local en validacion; no activado en produccion. Fecha: 2026-11-16.
El usuario aprobo priorizar E2EE, sustituir la inspeccion del servidor en chats privados y utilizar un SDK Flutter separado.

## Alcance implementado

- Flutter 3.38.10 / Dart 3.10.9 separado del SDK anterior; CI alineado y libsignal 9.0.1 fijado.
- Identidad Signal por cuenta y dispositivo, claves privadas y sesiones en una boveda SQLite cifrada con AES-256-GCM-SIV; clave maestra en almacenamiento seguro separado del token de acceso. Marcador Android en no_backup para detectar restauraciones incompatibles. Transaccion atomica del ratchet antes de exponer resultados.
- Registro autenticado de claves publicas, Kyber y preclaves. Mongo consume cada preclave en una operacion atomica; repetir registro no repone claves consumidas ni sustituye identidades revocadas.
- Activacion explicita por conversacion con ambos participantes preparados. Tras activarla, el servidor rechaza texto/fotos del contrato legado, incluso ante una carrera con la activacion. El historial antiguo no se cifra retroactivamente.
- Sobre por dispositivo, vinculado a conversacion, emisor, destinatario e identificador de operacion. Reintentos reutilizan ciphertext e identificador persistidos; opcion de reenvio pendiente. Nunca se usa la maqueta como alternativa ante un fallo.
- Fotos y WAV privados: clave y nonce distintos por archivo, cifrado autenticado con conversacion e identificador como datos asociados; claves y tipo dentro del mensaje Signal. Descarga mediante API autenticada; sin SAS ni CDN publico. La app descifra en memoria y no crea un archivo de audio descifrado. El usuario abre expresamente el contenido recibido.
- Voz Android: permiso de microfono solicitado al grabar, hasta 60 segundos, detener, escuchar, cancelar y enviar; captura PCM y WAV en memoria. Reproduccion nativa con MediaDataSource y limpieza al detener o salir.
- Acuse real del receptor mediante POST /v1/engagement/conversations/{id}/delivered; doble marca de entrega y estilo distinto de lectura. Un evento SignalR por si solo no confirma entrega. Lectura se solicita cuando el chat esta visible y se siguen los mensajes recientes.
- Comparacion de numeros de seguridad por par de dispositivos. Los cambios de identidad fijada no se aceptan automaticamente.

## Rutas nuevas (deshabilitadas por defecto)

Grupo /v1/engagement/chat-keys, con autenticacion, limite de peticiones y Cache-Control private, no-store:

- PUT /devices; GET /devices; DELETE /devices/{deviceId}.
- POST /devices/{deviceId}/claim para otro dispositivo propio.
- GET /conversations/{id}/devices y POST /conversations/{id}/devices/{deviceId}/claim.
- POST /conversations/{id}/enable y POST /conversations/{id}/messages.
- PUT y GET /conversations/{id}/attachments/{attachmentId}.

Los adjuntos son ciphertext opaco, hasta 8 MiB en API; la app limita el original a 5 MiB y WAV a 60 segundos. Solo participantes de una conversacion privada no bloqueada pueden cargar y descargar.

## Configuracion para pruebas, aun no para produccion

Crear un contenedor Blob llamado chat-private con acceso publico deshabilitado. No asociarlo a la ruta publica de Front Door/CDN. Configurar Chat__StorageConnectionString con la conexion real de esa cuenta (preferiblemente referencia de Key Vault), sin pegar su valor en documentacion. El adaptador rechaza un contenedor publico y no lo crea automaticamente.

Chat__E2eeEnabled=true habilita las rutas en el backend de pruebas. La app se compila con --dart-define=CHAT_E2EE=true. Ambos usuarios usan Android y eligen Preparar chat privado; la primera preparacion puede no activar hasta que el contacto tambien registre sus claves. La proteccion predeterminada permanece desactivada hasta completar la validacion descrita abajo.

No se necesita que Azure Key Vault reciba claves privadas de chat. E2EE es independiente de la clave de direcciones de pedidos. SignalR/Redis siguen siendo transporte de avisos, no prueba de entrega ni autoridad criptografica.

## Moderacion, reportes y compatibilidad

El chat privado no manda texto, fotos ni voz descifrados a Content Safety. Mantiene bloqueo, limite de abuso y reporte de la conversacion. La pantalla de envio explica la ausencia de moderacion automatica. No hay un clasificador local que garantice contenido adecuado. El envio voluntario de evidencia seleccionada de mensajes al moderador todavia no esta implementado; el reporte actual no adjunta contenido descifrado ni claves.

Android es la plataforma implementada para boveda y audio. Otras plataformas fallan de forma explicita y no degradan a texto en claro. Dependencia libsignal: wrapper de terceros con licencia AGPL-3.0; revisar sus obligaciones antes de distribuir. No se afirma auditoria criptografica independiente ni equivalencia completa con WhatsApp.

## Validacion y pendientes de activacion

Evidencia local final: 46 pruebas de Engagement aprobadas; suite completa Flutter de 279 pruebas aprobada y 6 pruebas HTTP de mensajes aprobadas tras agregar dos casos de entrega y rechazo seguro. Analisis Flutter sin incidencias; 139 archivos comprobados por dart format sin cambios; ANDROID-OK y PIPELINE-OK (54 checks). APK debug compilado con CHAT_E2EE=true. Dos pruebas con Mongo real y replica set temporal aprobadas: consumo concurrente sin reutilizacion, revocacion, rechazo de degradacion, destinatarios ajenos, idempotencia y acuse de entrega. Prueba nativa Signal cubre alteracion, identidad fijada, restauracion de registros, mensajes fuera de orden y autenticacion de adjuntos con contexto distinto. No equivale a dos dispositivos reales ni a Blob de Azure validado.

Pendiente: pruebas con Blob real, dos Android y cuentas distintas, segundo dispositivo, revocacion, perdida/restauracion de claves, agotamiento y reposicion de preclaves, rotacion de claves firmadas, gestion de slots revocados y retencion/borrado de adjuntos huerfanos. Actualmente hay hasta cinco slots inmutables por cuenta y cien preclaves iniciales; no activar ampliamente hasta completar ese ciclo de vida. Verificar logs, outbox y push sin contenido privado; no declarar validacion de producto a partir del lint o de dobles HTTP.

No se encontraron dispositivos ADB conectados durante esta ejecucion. No se modifico Azure ni se publicaron cambios remotos.

## Referencias

- https://github.com/signalapp/libsignal
- https://signal.org/docs/specifications/doubleratchet/
- https://signal.org/docs/specifications/sesame/
- https://pub.dev/packages/libsignal/versions/9.0.1
- https://pub.dev/packages/record/versions/6.2.1

## Preparacion local 2026-11-17

MongoDB replica set, Redis y Azurite iniciados con docker compose; servicios saludables. Contenedor Blob chat-private verificado sin acceso publico: escritura/lectura de bytes aleatorios correcta y acceso anonimo HTTP 403. Variables Chat__E2eeEnabled=true y Chat__StorageConnectionString=UseDevelopmentStorage=true configuradas exclusivamente en .env local; no representan valores de produccion.

API iniciada por el usuario: /health/live y /health/ready HTTP 200 en 127.0.0.1:5188. APK debug compilado con API_MODE=live, CHAT_E2EE=true y API_BASE_URL=http://127.0.0.1:5188. Telefono USB detectado e instalado sin borrar datos. Emulador Medium_Phone_API_35 arrancado y autorizado por el usuario; ambos conectados mediante adb reverse tcp:5188 tcp:5188.

Validacion funcional entre cuentas pendiente de inicio de sesion y ejecucion: texto bidireccional, entrega frente a lectura, imagen privada, voz (cancelar/revisar/enviar), reconexion, bloqueo, identidad y no degradacion. Preparacion de contenedores y health checks no constituyen aceptacion para produccion. Continuan las limitaciones de ciclo de vida de claves y adjuntos documentadas arriba.

## Correccion UX de voz y estados (2026-11-17)

El microfono se ofrece tambien antes de la activacion y conduce a preparar el dispositivo y el chat privado; no inicia grabacion ni envia audio sin cifrar. Enviado muestra una marca gris, Entregado dos marcas grises, Leido dos marcas celestes, con texto visible y semantica accesible. El receptor confirma entrega desde la bandeja tras recuperar mensajes, sin marcar lectura; el chat conserva la condicion de visibilidad para lectura. Refresco de respaldo cada cuatro segundos y recarga pendiente si llega un aviso durante una consulta. Un telefono desconectado o app sin recibir no se declara entregado.

Pruebas locales de contratos HTTP y widgets: 41 aprobadas, incluida diferenciacion de texto, icono y color de cada estado. Instalacion actualizada en dispositivos y recorrido humano pendientes de resultado; no se certifica produccion por estas pruebas.

### Correccion local de sesion y adjuntos (2026-11-17)
- TokenStorage fija explicitamente FlutterSecureStorage en Android: el plugin 9.2.4 conserva el nombre anterior al alternar almacenes. Logout elimina solo claves de sesion, conservando las claves del chat.
- Se retira el dialogo repetido de preparacion; el permiso nativo de microfono permanece bajo control de Android. No se omite autenticacion ni autorizacion.
- Fotos con vista previa y MIME detectado por firma; errores visibles. Adjuntos con timeout de 60 segundos; rutas de chat excluidas de cache HTTP.
- Pedido conserva direccion seleccionada y recentra mini mapa; selector admite tocar un punto.
- Build debug local; recorrido de voz/fotos entre dos personas pendiente de confirmacion en telefonos. No acredita produccion.


### Notificaciones privadas y bandeja (2026-11-17)

- Android MessagingStyle muestra remitente, avatar HTTPS cuando esta disponible y texto descifrado localmente; fotos y voz muestran su tipo. FCM recibe solo deepLink, accountId y tipo, nunca contenido de mensajes ni claves.
- El motor FCM consulta la API autenticada y usa las claves ya instaladas; no registra dispositivos ni repone claves desde un push. Sin red o claves se muestra aviso discreto; sin sesion, otro destinatario o acceso denegado se omite.
- Canal Mensajes con visibilidad privada en pantalla bloqueada, agrupacion por conversacion y toque hacia ruta validada. Mostrar un aviso no marca lectura. El sistema y la configuracion del usuario controlan la presentacion final.
- Renovacion de token serializada con transaccion SQLite exclusiva entre UI y FCM, sin almacenar credenciales en esa base. La clave del chat permanece en su almacen seguro anterior.
- Bandeja con busqueda por nombre, filtro sin leer, tarjetas y vista previa solo en memoria; no se incorpora texto privado a la cache HTTP.
- Requiere reiniciar la API local para usar el emisor FCM data-only. Android puede retrasar la entrega si restringe la actividad de fondo. Validacion FCM real entre ambos telefonos pendiente; no se acredita produccion por build o pruebas con dobles.

Validacion local del incremento: 56 pruebas aprobadas (sesion, push_seguro, push_controlador, diseno_maqueta y token_storage_isolation); analisis de archivos modificados sin problemas; formato 15 archivos sin cambios. APK debug CHAT_E2EE=true/API_MODE=live/API_BASE_URL=http://127.0.0.1:5188 compilado e instalado con install -r (Success) en 096fd2cc784f y ZY32JKH7KW; ambas MainActivity iniciadas. Pendiente reinicio de API y recorrido FCM real entre cuentas.


### Correccion de carga por renovacion de sesion (2026-11-17)
Ambos Android registraron DatabaseException al ejecutar PRAGMA busy_timeout mediante execute. La apertura del bloqueo de renovacion fallaba y conservaba tokens vencidos; las pantallas recibian 401 aunque /health/live y /health/ready respondian 200. Corregido usando rawQuery en PRAGMA que devuelve filas; se revisaron journal_mode y secure_delete del vault. Prueba de regresion simula el rechazo Android y comprueba renovar/persistir/reutilizar el token; 8 pruebas de sesion/almacenamiento aprobadas. No se omite autorizacion ni se borran datos del usuario.


### Seguridad automatica y recuperacion comprobada (2026-11-17)

Sustituye el recorrido anterior de activacion manual: el inicio/restauracion de sesion prepara las claves; la conversacion se habilita al disponer de claves de ambos participantes. La app habilita CHAT_E2EE por defecto y nunca envia un nuevo mensaje por la ruta sin cifrar cuando espera preparacion segura. Los permisos de grabacion los administra Android.

Causa encontrada en ambos telefonos: archivo SQLite de una inicializacion fallida, vacio y sin clave local. Se comprueba sqlite_master y COUNT de state antes de generar la clave. Si existe cualquier estado cifrado, se conserva y se rechaza la recuperacion automatica. No se borraron bases ni historiales.

Evidencia real: ambos dispositivos registraron claves con la API y emitieron security ready; el usuario confirmo que ya se envian fotos y notas de voz. Las pruebas de adjuntos ejecutan cifrado/descifrado real con LibSignal y HTTP con doble, incluyendo alteracion y contexto de otra conversacion. La moderacion sigue adaptada a E2EE; no implica moderacion del servidor del contenido cifrado ni auditoria productiva.

Notificaciones: avatar descargado con limite de 5 MiB y reducido a 128 px, persona y shortcut duradero por cuenta/conversacion, icono monocromo de la marca. Sigue la integracion oficial de Android: https://developer.android.com/develop/ui/views/notifications/conversations . La presentacion concreta depende de Android y del fabricante; comprobacion visual final pendiente.

### Avatar de notificacion: correccion 2026-11-17

El usuario confirma fotos y voz enviadas y logo visible; foto del contacto no visible. Se corrige rechazo de HTTP local en debug, cache prematura de shortcut sin avatar y actualizacion de shortcuts existentes. HTTPS sigue obligatorio en release y cada redireccion se valida antes de descargar, sin credenciales de API al servidor de imagenes. Pruebas de politica y reintento en push_seguro_test.dart. Validacion visual pendiente: ADB no detecta dispositivos en esta sesion. No se declara resuelto en producto hasta recibir un nuevo push en ambos telefonos.

### Carga de historial privado (2026-11-17)

Reporte del usuario: error generico al abrir chat. La API local responde health/ready 200 y reverse 5188 esta activo en Xiaomi. Se detecta que el cliente rechazaba toda la conversacion ante un solo mensaje no disponible o no descifrable. Se aisla el fallo por mensaje conservando su ciphertext, se procesa en orden y se muestra aviso explicito de no disponibilidad. El acuse acumulativo no atraviesa un mensaje entrante no disponible, ni se muestran palomitas propias en el aviso. No se borran claves ni se cambia a texto plano. Prueba con dobles: siete pruebas de http_mensajes_test.dart aprobadas. Confirmacion del caso real pendiente tras instalar.

Confirmacion del usuario tras instalar: las conversaciones vuelven a cargar. Queda pendiente confirmar recuperacion de todos los mensajes. Se agrega comparacion semantica de sobres cacheados (el orden JSON no altera el mensaje; cualquier valor cambiado se rechaza) y prioridad a la copia original propia en el vault. Pruebas: privacidad 15 y mensajes HTTP 8 aprobadas; analisis de cinco archivos sin incidencias. No se promete recuperar historial de un dispositivo que carece de claves ni se comparte texto plano mediante la API.

### Experiencia de medios y envio (2026-11-17)

Mensajes y medios se representan de inmediato en una cola local por cuenta. Un reloj indica envio pendiente; solo la respuesta del servidor habilita el acuse de enviado. Los fallos conservan una unica burbuja con reintento. El caption de foto viaja dentro del contenido cifrado y sus reintentos reutilizan la operacion pendiente. El historial de presentacion se guarda en el vault cifrado; los medios descifrados se conservan solo en memoria con limite de 16 MB y limpieza al cambiar cuenta. La cola visible no sobrevive al cierre del proceso; la operacion criptografica pendiente conserva su propia recuperacion.

Fotos: preview ampliable, mensaje opcional y render local inmediato; descarga automatica de medios visibles. Voz: grabacion con contador, detener, revisar, descartar, envio y controles nativos en memoria de pausa/progreso. Burbujas de texto acotadas, metadatos compactos y etiquetas accesibles.

Rendimiento: las transacciones de lectura sin cambios no reescriben el vault; consultas de dispositivos en paralelo y eliminacion de lecturas redundantes antes de enviar. La insercion local inmediata no garantiza latencia de red ni entrega instantanea.

Evidencia local: 75 pruebas aprobadas de diseno, HTTP con dobles, privacidad, push y aislamiento de credenciales; analisis completo limpio y 143 archivos de formato sin cambios. Revision visual y tiempos reales en telefonos pendientes de aceptacion. No constituye validacion productiva.

Audio largo 2026-11-17: sin corte fijo al minuto ni limite de reproduccion de 2 MB. WAV se transfiere en bloques cifrados de hasta 1 MB, manifest autenticado dentro del mensaje. El servidor conserva su limite por bloque; no requiere cambio de API para esta transferencia. Se valida 75 segundos por prueba criptografica con bloques, alteracion y otra conversacion. Limites restantes: memoria/recursos del dispositivo y tamano del sobre criptografico; no se promete capacidad fisica infinita. Actualizar ambos clientes para interpretar descriptor version 2 antes de habilitar audio largo en produccion.
