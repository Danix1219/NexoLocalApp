# 060 - Cierre funcional de interes, busqueda y perfil

Fecha: 2026-11-21. Estado: implementacion local; aceptacion humana pendiente.
Constitucion: [rectora](../../constitution.md).

Estado: Borrador documental; implementacion local sin aprobacion humana.

## 1. Contexto

Cierre de brechas detectadas en la auditoria y evidencias del usuario.

## 2. Objetivo

Completar acciones existentes y mejorar su continuidad visual.

## 3. Alcance

Interes, busqueda, visor, avatar y experiencias. Sin ampliar la exposicion publica de cuentas.

## 4. Requisitos
- FR-001: Enviar y retirar interes con POST/DELETE del contrato existente; refrescar lecturas solo tras exito y conservar errores reales.
- FR-002: Cabecera completa y adaptable en ambos modos; descartar sugerencias de consultas obsoletas.
- FR-003: Visor propio y ajeno de prestador comparte enlace y QR; solo el propietario tiene lapiz; sin boton inferior duplicado.
- FR-004: Inventario de brechas con evidencia y limites de verificacion.
- FR-005: Tu cuenta carga avatar mediante upload/avatar y updateMe; conserva foto ante rechazo.
- FR-006: Mi experiencia elige pedidos con canReview; historial muestra valoraciones reales, sin inventarlas.
- FR-007: Lista de interesados recorre cursores conservando orden y rechaza ciclos.
- NFR-001: Privacidad, errores recuperables y ausencia de secretos o dependencias nuevas.

| Requisito | Comportamiento | Tarea | Criterio |
|---|---|---|---|
| FR-001 | Enviar y retirar interes con POST/DELETE del contrato existente; refrescar lecturas solo tras exito y conservar errores reales | T-001 | AC-001 |
| FR-002 | Cabecera completa y adaptable en ambos modos; descartar sugerencias de consultas obsoletas | T-002 | AC-002 |
| FR-003 | Visor propio y ajeno de prestador comparte enlace y QR; solo el propietario tiene lapiz; sin boton inferior duplicado | T-003 | AC-003 |
| FR-004 | Inventario de brechas con evidencia y limites de verificacion | T-004 | AC-004 |
| FR-005 | Tu cuenta carga avatar mediante upload/avatar y updateMe; conserva foto ante rechazo | T-005 | AC-005 |
| FR-006 | Mi experiencia elige pedidos con canReview; historial muestra valoraciones reales, sin inventarlas | T-006 | AC-006 |
| FR-007 | Lista de interesados recorre cursores conservando orden y rechaza ciclos | T-007 | AC-007 |
| NFR-001 | Privacidad, errores recuperables y ausencia de secretos o dependencias nuevas | T-004 | AC-004 |

## 5. Contratos y limites
API conserva la autoridad: POST/DELETE `/v1/engagement/requests/{id}/interest`, GET `/v1/engagement/requests/{id}/interested`, carga de medios y PATCH `/v1/identity/me` existentes. No se crea un perfil publico de cliente sin contrato de privacidad. No hay dominio HTTPS propio; los enlaces actuales usan nexolocal:// y requieren la app instalada.

## 6. Criterios de aceptacion
AC-001: accion de interfaz llega a HTTP para enviar y retirar.
AC-002: cabecera real a 320/390 px con texto ampliado; analisis de sugerencias vigentes.
AC-003: visitante dispone de compartir y copiar sin editar; propietario conserva un solo lapiz.
AC-004: informe distingue implementado de pendiente y no declara aceptacion productiva.
AC-005: pruebas existentes de contrato de perfil; carga real y moderacion pendientes de dispositivo.
AC-006: listado filtra canReview/myReviewStars; aceptacion con pedido real pendiente.
AC-007: prueba de dos paginas mantiene sort y cursor.

## 7. Dependencias
[038](../038-interes-e-interesados/spec.md), [029](../029-buscar-prestadores/spec.md), [031](../031-perfil-prestador/spec.md), [032](../032-mi-perfil-edicion/spec.md), [059](../059-fotos-perfil-zona-navegacion/spec.md).

## Aprobacion

Sin revisor humano identificado. Implementacion local no equivale a aprobacion. El validador documental heredado exige Borrador y rechaza tareas ejecutadas; conservar evidencia de implementacion sin fingir fase documental.

### Guardados y paridad de perfil - 2026-11-21
Guardados conserva autores publicos y estado guardado; pagina completa sin ciclos. El perfil del solicitante dispone de compartir, copiar y QR. El enlace se activa solo al tocar una accion, no al visualizar la foto: POST /v1/identity/me/profile-share y GET /v1/identity/profiles/{shareId}. Nombre y foto exclusivamente, sin datos de cuenta privados. Perfil compartido no disponible muestra reintento/error; no inventar contenido.


### Menu de solicitudes y consistencia - 2026-11-21
Tres puntos abre menu Editar/Eliminar, con confirmacion explicita y estado de envio. Edicion y creacion comparten contenido como unica entrada; el titulo requerido por API se deriva internamente y no se duplica en tarjetas. Avisos de copiar visibles sobre visor de foto. MiniMap usa mosaicos con respaldo y atribucion, conserva coordenadas seleccionadas.


## Incremento perfiles 2026-11-21
FR-P07: Unificar tarjeta completa y menu Editar/Eliminar de publicaciones propias. FR-P08: Pestanas Trabajos, Fotos, Informacion, Opiniones; galeria cuadrada con todas las imagenes y apertura individual. FR-P09: Solicitudes sin encabezados duplicados, con estado y contenido legibles.

FR-P10: Buscar y Buscar solicitudes alinean titulo a izquierda y ubicacion a derecha en una misma fila, sin truncar titulo, con soporte a 320 px y texto ampliado.

FR-P11: Interesados presenta identidad, datos y nota con jerarquia clara; comparar comparte seleccion y ruta del feed con estado visible. FR-P12: ubicacion de busqueda de una linea con elipsis y acceso al texto completo.
