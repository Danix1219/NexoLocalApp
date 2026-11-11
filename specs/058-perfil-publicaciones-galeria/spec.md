# 058 — Perfil y publicaciones con galería

Estado: Borrador documental; implementación local registrada; aceptación visual y cloud pendientes.

## 1. Contexto y alcance
Esta ficha registra la experiencia de fotos de perfil y portada, autoría de publicaciones, galerías y edición de solicitudes/trabajos propios en Flutter.

## 2. Actores y precondiciones
Cuenta autenticada propietaria de la publicación para editar o eliminar. Las fotos se adjuntan solo después de aprobación del backend y el perfil ajeno se consulta mediante datos públicos.

## 3. Requisitos funcionales
- FR-001: tocar avatar o portada abre vista ampliada con zoom y acción para cambiar la foto; la edición de datos queda en el contenido del perfil.
- FR-002: solicitudes propias y ajenas muestran nombre completo y avatar actuales publicados por Identity.
- FR-003: solicitudes permiten hasta seis fotos aprobadas; la galería avanza por deslizamiento sin flechas superpuestas y el contador sigue la página. Trabajos siguen el mismo patrón.
- FR-004: editar solicitudes abiertas y trabajos propios permite modificar texto, opciones y fotos, conserva ubicación/categoría y vuelve a pasar moderación/autorización del servidor.

## 4. Requisitos no funcionales y datos
- NFR-001: no incluir claves Azure ni acceder a MongoDB desde Flutter; si falla una operación el borrador permanece visible.

## 5. Frontera y decisiones
Los contratos de publicación y medios se rigen por el [catálogo backend](../../../API_NexoLocal/docs/endpoints.md) y las [fichas de operaciones](../../../API_NexoLocal/docs/contracts/fichas-operaciones.md). La aplicación no infiere que un medio está aprobado hasta confirmarlo con la API.

## 6. Aceptación local
- AC-001 → FR-001: vista ampliada permite inspeccionar la foto y cambiarla desde el perfil.
- AC-002 → FR-002/FR-003: solicitud con cuenta real muestra autor actual y galería con contador desde 1/N hasta N/N.
- AC-003 → FR-004: PATCH de cada tipo usa la ruta real y preserva imágenes existentes por UUID.
- AC-004 → FR-004/NFR-001: 401/404/409/503 se muestran como error, sin simular éxito en modo remoto.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-005 | AC-001,AC-004 |
| FR-002 | T-002,T-005 | AC-002,AC-004 |
| FR-003 | T-003,T-005 | AC-002,AC-004 |
| FR-004 | T-004,T-005 | AC-003,AC-004 |
| NFR-001 | T-004,T-005 | AC-003,AC-004 |

## Aprobación
Implementación local registrada; pruebas cloud y aceptación visual humana pendientes.
