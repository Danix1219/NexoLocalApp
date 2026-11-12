# 059 — Fotos de perfil, zona y navegación

Estado: Borrador documental; implementación local registrada; validación física y aceptación humana pendientes.

## 1. Contexto y alcance
Esta ficha registra los cambios móviles para mostrar y actualizar fotos de perfil y portada, elegir y recuperar la zona de atención del prestador, y navegar desde publicaciones al perfil de su autor. Mantiene Flutter y los contratos disponibles del backend.

## 2. Actores y precondiciones
- Cuenta autenticada para cambiar sus medios y datos profesionales.
- Prestador con perfil profesional para configurar ubicación, foto y portada.
- API disponible para cargar medios y obtener perfiles públicos; la ubicación exacta residencial permanece privada.

## 3. Requisitos funcionales
- FR-001: avatar y portada muestran un indicador de carga mientras la imagen se procesa; ante error o rechazo se conserva la imagen anterior.
- FR-002: el alta y el perfil profesional permiten elegir o cambiar foto, portada y zona real; la zona guardada se recupera y su etiqueta pública corresponde al lugar elegido.
- FR-003: la ubicación del prestador se presenta de forma aproximada, conserva el radio configurado y no expone el punto residencial exacto.
- FR-004: tocar el nombre o la foto de quien publicó abre su perfil público; volver desde una pestaña raíz secundaria dirige a Inicio.

## 4. Requisitos no funcionales y datos
- NFR-001: usar miniaturas adecuadas para avatares, mantener breves las cachés privadas y no registrar ni exponer ubicación exacta, tokens o SAS.

## 5. Frontera y decisiones
Las operaciones móviles de imágenes y perfiles siguen los contratos del [catálogo backend](../../../API_NexoLocal/docs/endpoints.md) y las [fichas de operaciones](../../../API_NexoLocal/docs/contracts/fichas-operaciones.md). La aplicación conserva el punto residencial exacto como dato privado y muestra solo la zona aproximada. Los dobles de pruebas no acreditan una sesión real ni la aceptación visual en dispositivo.

## 6. Aceptación local
- AC-001 → FR-001: el indicador aparece durante la carga y la foto anterior se mantiene ante error o rechazo.
- AC-002 → FR-002: alta y edición recuperan foto, portada y zona elegida sin una ubicación ficticia.
- AC-003 → FR-003/FR-004/NFR-001: la publicación abre el perfil correcto, la zona no revela el punto exacto y el retroceso desde pestañas secundarias vuelve a Inicio.
- AC-004 → FR-001/FR-002/NFR-001: pruebas móviles, análisis y compilación quedan registrados; la revisión visual y los recorridos físicos requieren aceptación humana.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-005 | AC-001,AC-004 |
| FR-002 | T-002,T-005 | AC-002,AC-004 |
| FR-003 | T-003,T-005 | AC-003,AC-004 |
| FR-004 | T-004,T-005 | AC-003,AC-004 |
| NFR-001 | T-003,T-005 | AC-001,AC-003,AC-004 |

## Aprobación
Pendiente de revisión visual y aceptación humana en dispositivo con una cuenta real. La verificación automatizada local no representa aceptación de producto.
