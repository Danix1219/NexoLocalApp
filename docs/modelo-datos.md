# Datos del consumidor Flutter

Diseño propuesto, sin SQLite ni aplicación creados. La API conserva autoridad de datos y permisos; la app no lee MongoDB, Redis o Neo4j.

| Dato local | Partición y política | Sincronización / limpieza |
|---|---|---|
| Catálogo/resúmenes públicos | Clave de consulta/versión, fecha y caducidad | Mostrar antigüedad, refrescar al reconectar, no mezclar con información privada |
| Guardados y borradores | userId y recurso; protección local por ratificar | Comando idempotente y estado pendiente/error; borrar al logout/eliminar según política |
| Mensajes pendientes | userId/conversationId/clientMessageId | Confirmar solo con servidor; mismo ID al reintentar; cursor recupera huecos |
| Credenciales | Almacenamiento seguro, fuera de SQLite/logs | Refresh coordinado, purga al cerrar sesión y cambio de cuenta |
| Contacto/domicilio privado | Minimizar; nunca caché compartida | Revalidar estado/consentimiento; retirar copia/ruta al cancelar, logout o revocar |

Definir esquema/migración local, límites de retención, cifrado/protección y resolución de conflictos antes de Ready técnico. Conflicto remoto exige refrescar; SQLite no confirma aceptación, moderación o permisos. Logout offline es local inmediato con revocación remota pendiente, no éxito remoto ficticio.

Los DTO proceden del [contrato API](../../API_NexoLocal/docs/contracts/README.md); nunca copiar documento MongoDB a widgets. [Acuerdo común](../../docs_nexo/SDD_ALINEACION.md). El recorrido Ana→logout→Carlos verifica credenciales, caché, imágenes, guardados, borradores y mensajes.

La [spec 016 de sincronización local](../specs/016-sincronizacion-local/spec.md) es autoridad del comportamiento transversal de cola/migraciones/conflictos; este recorrido conserva sus reglas de negocio y contratos, sin duplicar su implementación.
