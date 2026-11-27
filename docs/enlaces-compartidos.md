# Enlaces compartidos de Nexo Local

Estado 2026-11-17: apertura de enlaces y visor anterior confirmados por el usuario; nueva tarjeta QR validada localmente, recorrido fisico del nuevo incremento pendiente.

El proyecto no dispone de dominio propio (confirmado por el usuario). Se retira el dominio ajeno nexolocal.mx de los enlaces copiados. Los enlaces nuevos usan el esquema Android registrado:

- Perfil publico de prestador: `nexolocal://provider/{providerId}`.
- Publicacion: `nexolocal://provider/{providerId}/work/{workId}`.

La publicacion se consulta mediante el contrato existente de trabajos del prestador; se muestra la publicacion exacta y se conserva un estado explicito si fue eliminada o dejo de estar disponible. No se redirige a contenido ajeno. El destino se valida y se conserva mientras se restaura/inicia sesion.

El visor compartido de foto cliente/prestador usa fondo oscuro con blur, foto circular, nombre y edicion para propietario. Compartir nativo, copiar y QR estan disponibles cuando existe perfil publico de prestador. Cliente sin perfil publico no tiene una ruta compartible en los contratos actuales: no fabricar un enlace a `my-profile`, porque abriria el perfil del receptor. Esta capacidad sigue pendiente de contrato y decision de privacidad.

Los esquemas propios abren la app instalada cuando el servicio de origen permite lanzarlos. No hay pagina web ni instalacion automatica si la app no esta instalada. Algunos servicios no convierten estos enlaces en texto pulsable. Para HTTPS universal se necesita dominio controlado, assetlinks.json con huellas reales de firma y asociacion iOS cuando aplique; no se agregaron dominios ni verificaciones ficticias.

QR se genera localmente con qr_flutter; no se transmiten datos a servicios de QR. Solo contiene el enlace publico, sin tokens ni informacion de contacto.

Validacion local: pruebas de rutas propias/recorridos no permitidos y visor propietario/visitante; flutter analyze y compilacion Android. Prueba real del enlace y QR pendiente de confirmacion en telefonos.

## Tarjeta QR y avisos leidos (2026-11-17)

La tarjeta presenta marca, foto y nombre fuera del codigo, alto contraste negro/blanco, correccion Q y margen blanco de cuatro modulos calculado segun su densidad. Tiene compartir y copiar enlace; admite scroll, pantallas pequenas y texto ampliado. No se superpone el logotipo en los modulos.

No se necesita otro endpoint para prestadores: GET /v1/discovery/providers/{id} ya es publico y excluye datos privados. Un QR no crea un perfil ni publica informacion nueva. La ausencia de dominio impide prometer apertura HTTPS universal.

Las notificaciones se omiten solo para la conversacion actualmente visible con app en primer plano; otras conversaciones siguen notificando. Abrirla retira su aviso. Tras confirmacion de lectura por la API se guarda el ultimo messageId por cuenta/conversacion en almacenamiento seguro, compartido entre UI y FCM. Se comprueba antes y despues de publicar para evitar carreras; UUIDv7 anteriores al marcador no vuelven a notificar. Cerrar sesion purga marcadores. Entrar en otra pantalla no marca mensajes como leidos.

Evidencia: flutter analyze sin incidencias; 70 pruebas aprobadas. PNG del QR renderizado en anchos 320/390 decodificados con ZXing hacia el enlace exacto. Recorrido nativo nuevo entre telefonos pendiente.
