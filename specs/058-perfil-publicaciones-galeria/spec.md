# 058 Perfil y publicaciones con galería

Estado: implementado localmente; aceptación visual y cloud pendiente.

FR-001: tocar avatar o portada abre vista ampliada con zoom y acción para cambiar la foto; editar datos del perfil está dentro del contenido.
FR-002: solicitudes propias y ajenas muestran el nombre completo y avatar actuales que publica Identity para el autor.
FR-003: crear solicitudes admite hasta seis fotos aprobadas; al ver varias se navega por deslizamiento sin flechas superpuestas y el contador superior cambia con la página. Trabajos usan el mismo patrón.
FR-004: editar solicitudes abiertas y trabajos propios usa el estilo del compositor para texto, opciones y fotos; conserva ubicación/categoría. El servidor vuelve a moderar y autoriza.
NFR-001: ninguna clave de Azure ni acceso a Mongo desde Flutter. Fallos dejan el borrador visible.

AC-001: foto ampliada y cambiar foto desde la vista.
AC-002: solicitud propia usa cuenta real y fotos múltiples con contador 1/N a N/N.
AC-003: PATCH de cada tipo usa su ruta real y preserva imágenes existentes por UUID.
AC-004: 401/404/409/503 se muestran como error; no se simula éxito en modo live.

Contratos de autoridad: backend `specs/endpoints/05-trabajos/patch-works-id.md` y `specs/endpoints/06-solicitudes/patch-requests-id.md`.
