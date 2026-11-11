# 057 — Integración de backend disponible en Flutter
Estado: Borrador documental; implementación y pruebas locales ejecutadas, aceptación humana pendiente.

## 1. Contexto y alcance
Persona con cuenta y prestador con perfil consultan/publican contenido real de los grupos 01–06 disponibles. App Flutter conserva NexoApi, Riverpod, rutas actuales y diseño aprobado. No crea endpoints de interés, detalle, pedidos o feed que todavía no existen.

## 2. Actores y precondiciones
Cuenta real, sesión para mutaciones y perfil publicado para trabajos/oportunidades. Backend accesible con Mongo/Redis y Content Safety configurado para publicar. Solo fake explícito permite datos de ejemplo en los grupos conectados.

## 3. Requisitos funcionales
- FR-001: Consumir catálogo, búsqueda/sugerencias/mapa, trabajos y solicitudes con sus campos y cursores reales; errores explícitos sin demo implícita.
- FR-002: Publicar con ubicación real, mantener clave de reintento por payload, cerrar solicitudes y actualizar pantallas; recomendar/retirar y borrar trabajos según propiedad.

## 4. Requisitos no funcionales y datos
- NFR-001: Sesión/caché aisladas, estados privados sin caché obsoleta, logs sin ubicación ni consultas privadas y ninguna imagen inventada. Contratos backend autoritativos, no acceso a Mongo desde Flutter.

## 5. Frontera y decisiones
[Solicitudes backend](../../../../nexolocal_api/NexoLocalApi/specs/endpoints/06-solicitudes/implementacion.md), [trabajos](../../../../nexolocal_api/NexoLocalApi/specs/endpoints/05-trabajos/implementacion.md). Catálogo backend usa categories; servicios consumen todas las páginas con detección de cursor repetido. Resumen de intereses degradado se conserva como desconocido. Mapa abre la solicitud mediante opportunities existente y comprueba id; no inventar GET detalle. Interés/guardados ausentes no simulan éxito en auto; fotos Próximamente. Publicaciones requieren moderación real.

## 6. Aceptación local
- AC-001 → FR-001/NFR-001: test/integration verifica catálogo, tres listas con cursor, bucle inválido, claves y degradación.
- AC-002 → FR-002/NFR-001: test/unit verifica modelo, filtros, widget de recomendación POST/DELETE y trabajo sin imágenes.
- AC-003 → FR-001/FR-002/NFR-001: test/security verifica modo remoto, privacidad, logs y ausencia de caché de estado privado; flutter analyze y suite completa.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-003 | AC-001,AC-003 |
| FR-002 | T-002,T-003 | AC-002,AC-003 |
| NFR-001 | T-001,T-002,T-003 | AC-001,AC-002,AC-003 |

Evidencia y límites: [integración](../../docs/integracion-backend-01-06.md). Dobles HTTP no acreditan Atlas/Content Safety ni revisión de cada recorrido físico.

## Aprobación
Sin revisor humano identificado. La evidencia técnica no firma Ready ni aceptación cloud.


## Incremento de medios reales 2026-11-10
- FR-003: seleccionar y subir fotos reales para avatar, portada personal/profesional y publicaciones; esperar aprobaci?n antes de guardar la referencia. Reutilizar composici?n actual de pantallas.
- NFR-002: nunca incluir credenciales Azure en Flutter ni Bearer en Blob; ocultar SAS en errores, no simular aprobaci?n y mantener borrador si falla.
- AC-004 ? FR-003/NFR-002: test/integration/http_imagenes_test.dart verifica polling y rechazo/portada; test/security verifica transporte, URL HTTPS y logs. Suite completa y flutter analyze; nube se comprueba por separado en backend.
- T-004 ? FR-003/NFR-002/AC-004: conectar cuenta, perfil profesional y ambos compositores; ejecutar pruebas existentes y construir APK local. Sin nuevo job, Terraform ni archivo de pruebas.

Autoridad: [incremento backend de medios](../../../../nexolocal_api/NexoLocalApi/specs/endpoints/14-imagenes-cdn/implementacion.md). Reemplaza el estado hist?rico Fotos Pr?ximamente; chat privado y CDN siguen fuera. Fotos m?ximo5MB y hasta6 por trabajo; no guardar una imagen processing. La instalaci?n local no acredita todos los recorridos f?sicos del usuario.


## Corrección de publicaciones largas, 2026-11-10
- FR-004: tarjetas de solicitud y trabajo muestran tres líneas y acción Ver más/Ver menos solo cuando el texto desborda; al expandir se lee completo. El modelo consume `description` completo de listados y conserva compatibilidad con `descriptionExcerpt`.
- AC-005 -> FR-004: prueba widget en ancho estrecho y texto corto, expandir/contraer; prueba HTTP del backend verifica texto completo en mine/opportunities.
- T-005 -> FR-004/AC-005: componente compartido en tarjetas y consumo del campo completo, documentar y verificar.
