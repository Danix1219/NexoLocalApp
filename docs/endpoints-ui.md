# Consumo móvil e intenciones — 0.4.0

Autoridad de contrato: [inventario API](../../API_NexoLocal/docs/contracts/inventario.json), [fichas](../../API_NexoLocal/docs/contracts/fichas-operaciones.md). Son diseños por formalizar, no integración aprobada. Una operación puede atender varias vistas/intenciones; no exige pantalla nueva. REST público relativo a /api/v1, WS/GraphQL con raíz propia.

| EP | Intención de negocio | Spec consumidora primaria | Spec API primaria |
|---|---|---|---|
| EP-001 | Solicitar verificación o recuperación del teléfono | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-002 | Comprobar código y obtener prueba de control | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-003 | Crear cuenta única y consentimiento | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-004 | Iniciar sesión con teléfono y contraseña | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-005 | Renovar sesión sin login repetido | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-006 | Restablecer acceso y revocar sesiones previas | [017-cuenta-recuperacion-sesiones](../specs/017-cuenta-recuperacion-sesiones/spec.md) | [nv-16](../../API_NexoLocal/specs/nv-16/spec.md) |
| EP-007 | Cerrar sesión actual en backend y dispositivos | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-008 | Recuperar cuenta, capacidades y preferencias | [004-identidad-sesion](../specs/004-identidad-sesion/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-009 | Editar nombre, intereses y preferencias | [017-cuenta-recuperacion-sesiones](../specs/017-cuenta-recuperacion-sesiones/spec.md) | [nv-16](../../API_NexoLocal/specs/nv-16/spec.md) |
| EP-010 | Consultar sesiones de sus dispositivos | [017-cuenta-recuperacion-sesiones](../specs/017-cuenta-recuperacion-sesiones/spec.md) | [nv-16](../../API_NexoLocal/specs/nv-16/spec.md) |
| EP-011 | Revocar otro dispositivo | [017-cuenta-recuperacion-sesiones](../specs/017-cuenta-recuperacion-sesiones/spec.md) | [nv-16](../../API_NexoLocal/specs/nv-16/spec.md) |
| EP-012 | Solicitar eliminación integral | [012-notificaciones-borrado](../specs/012-notificaciones-borrado/spec.md) | [nv-12](../../API_NexoLocal/specs/nv-12/spec.md) |
| EP-013 | Consultar progreso del borrado | [012-notificaciones-borrado](../specs/012-notificaciones-borrado/spec.md) | [nv-12](../../API_NexoLocal/specs/nv-12/spec.md) |
| EP-014 | Listar categorías, especialidades y sectores | [018-catalogo-seleccion](../specs/018-catalogo-seleccion/spec.md) | [nv-17](../../API_NexoLocal/specs/nv-17/spec.md) |
| EP-016 | Crear perfil de persona o negocio | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-017 | Consultar perfil público y señales | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-018 | Consultar perfil editable y completitud | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-019 | Actualizar datos comerciales y servicios | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-020 | Editar modalidad y zona de atención | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-021 | Configurar horarios y urgencias | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-022 | Definir visita y precios orientativos | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-023 | Confirmar vigencia de información | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-024 | Retirar perfil de publicación | [006-perfiles](../specs/006-perfiles/spec.md) | [nv-06](../../API_NexoLocal/specs/nv-06/spec.md) |
| EP-025 | Buscar y filtrar prestadores por necesidad y zona | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-026 | Autocompletar servicios y términos reconocidos | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-027 | Comparar exactamente dos prestadores | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-028 | Buscar lugar para seleccionar ubicación | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-029 | Obtener etiqueta de zona desde punto | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-030 | Componer inicio por zona y modo | [007-descubrimiento](../specs/007-descubrimiento/spec.md) | [nv-07](../../API_NexoLocal/specs/nv-07/spec.md) |
| EP-031 | Publicar un trabajo realizado | [008-comunidad](../specs/008-comunidad/spec.md) | [nv-08](../../API_NexoLocal/specs/nv-08/spec.md) |
| EP-032 | Consultar trabajos filtrados y perfil | [008-comunidad](../specs/008-comunidad/spec.md) | [nv-08](../../API_NexoLocal/specs/nv-08/spec.md) |
| EP-033 | Abrir detalle de trabajo | [008-comunidad](../specs/008-comunidad/spec.md) | [nv-08](../../API_NexoLocal/specs/nv-08/spec.md) |
| EP-034 | Corregir contenido de trabajo | [008-comunidad](../specs/008-comunidad/spec.md) | [nv-08](../../API_NexoLocal/specs/nv-08/spec.md) |
| EP-035 | Retirar trabajo | [008-comunidad](../specs/008-comunidad/spec.md) | [nv-08](../../API_NexoLocal/specs/nv-08/spec.md) |
| EP-036 | Recomendar trabajo o perfil | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-037 | Retirar recomendación | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-038 | Consultar prestadores, trabajos o solicitudes guardados | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-039 | Guardar objetivo | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-040 | Quitar guardado | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-041 | Publicar experiencia o calificación | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-042 | Consultar opiniones y resumen | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-043 | Corregir experiencia | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-044 | Retirar experiencia | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-045 | Registrar vista, compartir o intención de contacto | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-046 | Consultar actividad de su perfil | [019-guardados-indicadores](../specs/019-guardados-indicadores/spec.md) | [nv-18](../../API_NexoLocal/specs/nv-18/spec.md) |
| EP-047 | Publicar necesidad de servicio | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-048 | Consultar solicitudes de zona y capacidad | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-049 | Abrir solicitud | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-050 | Corregir necesidad abierta | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-051 | Cerrar necesidad ya resuelta | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-052 | Retirar solicitud | [009-solicitudes](../specs/009-solicitudes/spec.md) | [nv-09](../../API_NexoLocal/specs/nv-09/spec.md) |
| EP-053 | Expresar interés | [021-interesados-candidatos](../specs/021-interesados-candidatos/spec.md) | [nv-20](../../API_NexoLocal/specs/nv-20/spec.md) |
| EP-054 | Retirar interés | [021-interesados-candidatos](../specs/021-interesados-candidatos/spec.md) | [nv-20](../../API_NexoLocal/specs/nv-20/spec.md) |
| EP-055 | Consultar interesados y ordenar | [021-interesados-candidatos](../specs/021-interesados-candidatos/spec.md) | [nv-20](../../API_NexoLocal/specs/nv-20/spec.md) |
| EP-056 | [Ampliación opcional] Preseleccionar candidato | [021-interesados-candidatos](../specs/021-interesados-candidatos/spec.md) | [nv-20](../../API_NexoLocal/specs/nv-20/spec.md) |
| EP-057 | [Ampliación opcional] Quitar preselección | [021-interesados-candidatos](../specs/021-interesados-candidatos/spec.md) | [nv-20](../../API_NexoLocal/specs/nv-20/spec.md) |
| EP-058 | Enviar pedido desde perfil, chat o interesado | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-059 | Consultar pedidos por modo y estado | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-060 | Consultar estado y logística autorizada | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-061 | Aceptar y opcionalmente fijar precio | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-062 | Rechazar pedido pendiente | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-063 | Cancelar servicio activo | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-064 | Declarar servicio resuelto | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-065 | Cambiar punto y referencias del servicio | [010-pedidos](../specs/010-pedidos/spec.md) | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-066 | Abrir o recuperar conversación por pareja | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-067 | Listar bandeja y no leídos por modo | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-068 | Recuperar historial o mensajes tras desconexión | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-069 | Enviar texto o foto aprobados | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-070 | Marcar lectura hasta secuencia | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-071 | Bloquear a contraparte | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-072 | Desbloquear contraparte | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-073 | Emitir ticket de conexión WebSocket | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |
| EP-074 | Recibir avisos de mensajes y pedidos | [011-mensajeria](../specs/011-mensajeria/spec.md) | [nv-11](../../API_NexoLocal/specs/nv-11/spec.md) |
| EP-075 | Moderar y registrar imagen | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-076 | Resolver acceso autorizado a medio | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-077 | Retirar archivo autorizado | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-078 | Reportar perfil, trabajo, experiencia o chat | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-079 | Consultar estado de sus reportes | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-082 | Generar borrador editable de solicitud o trabajo | [013-inteligencia](../specs/013-inteligencia/spec.md) | [nv-13](../../API_NexoLocal/specs/nv-13/spec.md) |
| EP-083 | Registrar token push y preferencias | [022-push-dispositivos](../specs/022-push-dispositivos/spec.md) | [nv-21](../../API_NexoLocal/specs/nv-21/spec.md) |
| EP-084 | Desvincular push del dispositivo | [022-push-dispositivos](../specs/022-push-dispositivos/spec.md) | [nv-21](../../API_NexoLocal/specs/nv-21/spec.md) |
| EP-085 | Consultar notificaciones persistentes | [022-push-dispositivos](../specs/022-push-dispositivos/spec.md) | [nv-21](../../API_NexoLocal/specs/nv-21/spec.md) |
| EP-086 | Marcar aviso leído | [022-push-dispositivos](../specs/022-push-dispositivos/spec.md) | [nv-21](../../API_NexoLocal/specs/nv-21/spec.md) |
| EP-091 | Obtener número del prestador para copiar | [025-contacto-consentimiento](../specs/025-contacto-consentimiento/spec.md) | [nv-25](../../API_NexoLocal/specs/nv-25/spec.md) |
| EP-092 | Obtener contacto privado de la contraparte | [025-contacto-consentimiento](../specs/025-contacto-consentimiento/spec.md) | [nv-25](../../API_NexoLocal/specs/nv-25/spec.md) |
| EP-093 | Buscar prestador para mencionar en una experiencia | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-094 | Listar experiencias propias | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-095 | Abrir experiencia individual y su prestador | [020-experiencias-reputacion](../specs/020-experiencias-reputacion/spec.md) | [nv-19](../../API_NexoLocal/specs/nv-19/spec.md) |
| EP-096 | Configurar chat y visibilidad del número | [025-contacto-consentimiento](../specs/025-contacto-consentimiento/spec.md) | [nv-25](../../API_NexoLocal/specs/nv-25/spec.md) |
| EP-097 | Dar o retirar permiso para compartir su teléfono | [025-contacto-consentimiento](../specs/025-contacto-consentimiento/spec.md) | [nv-25](../../API_NexoLocal/specs/nv-25/spec.md) |
| EP-098 | Consultar contexto y candidatos relacionados del grafo | [015-relaciones-opcional](../specs/015-relaciones-opcional/spec.md) | [nv-15](../../API_NexoLocal/specs/nv-15/spec.md) |
| EP-099 | Obtener motivos y política vigente de reporte | [005-contenido-seguro](../specs/005-contenido-seguro/spec.md) | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |

## Superficies sin invocación móvil directa

| EP | Superficie y razón | Spec API |
|---|---|---|
| EP-015 | administrativa; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-17](../../API_NexoLocal/specs/nv-17/spec.md) |
| EP-080 | administrativa; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-24](../../API_NexoLocal/specs/nv-24/spec.md) |
| EP-081 | administrativa; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-24](../../API_NexoLocal/specs/nv-24/spec.md) |
| EP-087 | interna entre servicios; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-05](../../API_NexoLocal/specs/nv-05/spec.md) |
| EP-088 | interna entre servicios; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-10](../../API_NexoLocal/specs/nv-10/spec.md) |
| EP-089 | infraestructura; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-01](../../API_NexoLocal/specs/nv-01/spec.md) |
| EP-090 | infraestructura; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-01](../../API_NexoLocal/specs/nv-01/spec.md) |
| EP-100 | interna entre servicios; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-25](../../API_NexoLocal/specs/nv-25/spec.md) |
| EP-101 | interna entre servicios; identidad administrativa/interna/infra propia, nunca credencial Flutter | [nv-04](../../API_NexoLocal/specs/nv-04/spec.md) |

## Consumo compartido y casos sin endpoint

016 usa EP-038/039/040 para sincronización; la intención de guardados tiene dueño 019. 006/007/009 reutilizan catálogo de 018. Perfil/pedido/chat integran contacto de 025; no copian autorización. 012 enlaza retiro de dispositivos con 022. EP-073, producido por S01, se consume en 011. EP-088/100/101 son exclusivamente entre servicios.

Selección local, mostrar/ocultar contraseña, navegación, Semantics, permisos Android y abrir compartir/copia/ruta no requieren endpoint adicional; la autorización del recurso se revalida por operaciones existentes cuando corresponda. ML de imagen es local en el teléfono (ML Kit, [spec 049](../specs/049-ia-generativa-y-ml/spec.md)); GenAI remoto usa EP-082 como `POST /v1/assist/draft`.

056/057/098 son opcionales; 024/095/097 son complementos de diseño con alcance/UX por ratificar. No se crea pantalla para cada uno ni se considera aceptado por figurar en catálogo. Cada EP consumido tiene FR-200+n/T-200+n/AC-200+n en su spec primaria. [Mapa bilateral completo](../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md).

## Consumo agregado en 0.3.0 (2026-11-08)

| Método | Ruta | Grupo | Pantalla | Spec |
|---|---|---|---|---|
| POST | `/v1/assist/draft` (EP-082, por formalizar) | `asistente` | Publicar → «Ayúdame a redactar» | [049](../specs/049-ia-generativa-y-ml/spec.md) |
| POST | `/v1/identity/devices` | `dispositivos` | Permiso de avisos, inicio de sesión, rotación del token | [050](../specs/050-notificaciones-push/spec.md) |
| DELETE | `/v1/identity/devices/{id}` | `dispositivos` | Cuenta → apagar avisos; cerrar sesión | [050](../specs/050-notificaciones-push/spec.md) |

El inventario de la API lista EP-083/084 como `PUT/DELETE /me/devices/{id}`; la app sigue el contrato detallado compartido por el backend (`/v1/identity/devices`). Si el backend publica la otra forma, solo cambia `HttpNexoApi.registerDevice/removeDevice`.
