# Personalizacion y gestion del chat

Incremento local 2026-11-19. Al abrir una conversacion se muestran los mensajes recientes con lista inversa, sin recorrido animado de todo el historial. Si el usuario consulta mensajes anteriores no se lo desplaza por cada refresco.

En el menu del chat: Fondo del chat. Cinco diseños vectoriales locales: Lino, Jardin, Brisa, Terracota y Noche. La seleccion pertenece a la cuenta/conversacion en este dispositivo; no cambia el fondo del contacto y se purga al cerrar sesion.

Mantener pulsado un mensaje propio confirmado en un chat privado abre sus acciones. Editar aparece para texto cifrado; fotos y audios pueden eliminarse, no se transforman en texto mediante la interfaz. El editor conserva el texto mientras se decide y requiere contenido no vacio (maximo 1000 caracteres). Eliminar para todos pide confirmacion y sustituye el contenido por Mensaje eliminado. Editado indica revision confirmada. Mensajes de sistema, ajenos, pendientes o no disponibles no ofrecen estas acciones.

Las modificaciones se muestran tras confirmacion de API, con estado ocupado y errores reales sin exito simulado. El texto editado viaja cifrado e incluye editOf autenticado. El backend valida autor, pertenencia, bloqueo y no resurreccion; conserva el orden original y publica messageUpdated. Los reintentos no pueden revertir una revision posterior. Autoridad contractual: docs/chat-edicion-eliminacion.md en NexoLocalApi.

La eliminacion es logica: no puede retirar capturas, copias previas o respaldos del otro dispositivo. Los blobs cifrados requieren politica separada de recoleccion; no se promete purga fisica. No se borran claves ni sesiones.

Evidencia local: 87 pruebas Flutter aprobadas (diseno_maqueta, http_mensajes, privacidad, push_seguro). Pruebas con widgets/dobles. Recorrido real entre dispositivos y revision humana pendientes. El backend necesita recompilarse y reiniciarse para cargar PATCH/DELETE nuevos.

## Temas coordinados
El icono de paleta en la cabecera abre Personalizar chat, tambien disponible en opciones. Cada estilo combina fondo, burbujas enviadas/recibidas, audio y metadatos; el selector anticipa los colores. Se mantiene el guardado local por cuenta/conversacion y los acuses de lectura conservan su significado.

Editar y eliminar usan panel contextual propio: vista previa del mensaje, colores del tema, guardado validado y confirmacion explicita antes de borrar. Cancelar no realiza peticiones. 53 pruebas de diseno aprobadas; revision humana pendiente.
