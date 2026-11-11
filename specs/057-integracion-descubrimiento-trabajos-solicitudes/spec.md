# 057 — Integración de backend disponible en Flutter

Estado: Borrador documental; implementación y pruebas locales registradas; aceptación humana pendiente.

## 1. Contexto y alcance
Personas con cuenta y prestadores consultan y publican contenido real de los grupos disponibles. Flutter conserva NexoApi, Riverpod, rutas y diseño aprobados. No se crean endpoints de interés, detalle, pedidos o feed que aún no existen.

## 2. Actores y precondiciones
Cuenta real y sesión para mutaciones; perfil publicado para trabajos y oportunidades. Backend y moderación de contenido deben estar disponibles para publicar. Solo el modo fake explícito permite datos de ejemplo.

## 3. Requisitos funcionales
- FR-001: consumir catálogo, búsqueda, sugerencias, mapa, trabajos y solicitudes con campos y cursores reales; mostrar errores explícitos sin demo implícita.
- FR-002: publicar con ubicación real y clave de reintento por payload, cerrar solicitudes y actualizar pantallas; recomendar, retirar y borrar trabajos según propiedad.
- FR-003: cargar fotos reales para avatar, portada personal/profesional y publicaciones; esperar aprobación antes de guardar referencias.
- FR-004: tarjetas muestran hasta tres líneas y permiten Ver más/Ver menos cuando el texto desborda, conservando descripción completa del backend.

## 4. Requisitos no funcionales y datos
- NFR-001: sesión y caché aisladas; estado privado no usa caché obsoleta; logs omiten ubicación y consultas privadas; no inventar imágenes ni acceder a Mongo desde Flutter.
- NFR-002: no incluir credenciales Azure ni enviar Bearer a Blob; ocultar SAS en errores, conservar borrador si falla y no simular aprobación.

## 5. Frontera y decisiones
La autoridad de contrato es el [catálogo backend](../../../API_NexoLocal/docs/endpoints.md) y las [fichas de operaciones](../../../API_NexoLocal/docs/contracts/fichas-operaciones.md). Los servicios recorren páginas con detección de cursores repetidos. Mapa abre solicitudes mediante oportunidades existentes, sin inventar GET de detalle. Interés/guardados ausentes no simulan éxito. La publicación requiere moderación real.

## 6. Aceptación local
- AC-001 → FR-001/NFR-001: pruebas HTTP verifican catálogo, listas paginadas, cursores inválidos, errores y degradación segura.
- AC-002 → FR-002/NFR-001: pruebas verifican modelos, filtros, mutaciones, propiedad y ausencia de éxito ficticio.
- AC-003 → FR-001/FR-002/NFR-001: pruebas de seguridad verifican modo remoto, privacidad, logs y caché privada.
- AC-004 → FR-003/NFR-002: pruebas verifican carga, aprobación/rechazo y privacidad de SAS; cloud se valida por separado.
- AC-005 → FR-004: pruebas widget/http verifican texto corto y largo, expansión y descripción completa.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-003 | AC-001,AC-003 |
| FR-002 | T-002,T-003 | AC-002,AC-003 |
| FR-003 | T-004,T-006 | AC-004 |
| FR-004 | T-005,T-006 | AC-005 |
| NFR-001 | T-001,T-002,T-003,T-006 | AC-001,AC-002,AC-003 |
| NFR-002 | T-004,T-006 | AC-004 |

La evidencia automatizada y la [integración registrada](../../docs/integracion-backend-01-06.md) no acreditan Atlas, Content Safety, CDN ni recorridos físicos con cuenta real.

## Aprobación
Sin revisor humano identificado. La evidencia técnica no representa aceptación cloud ni firma de producto.
