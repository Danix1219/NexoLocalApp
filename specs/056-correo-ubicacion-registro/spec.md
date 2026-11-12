# 056 — Correo, ubicación real, registro y Buscar

Estado: Borrador documental; implementación local registrada; aceptación humana pendiente.

## 1. Contexto y alcance
La app integra búsqueda de ubicaciones, restauración de la zona de la cuenta, confirmación del registro y presentación de Buscar. Los cambios usan operaciones backend existentes y no recurren a resultados de demostración implícitos.

## 2. Actores y precondiciones
Persona que se registra o consulta/cambia su ubicación. Se requiere conectividad para la búsqueda remota y endpoints Discovery disponibles para resolver zonas.

## 3. Requisitos funcionales
- FR-001: búsqueda explícita de ubicaciones, selección, mapa/GPS y confirmación muestran resultados reales, sin fallback de demostración.
- FR-002: restaurar punto, radio y etiqueta de la cuenta desde servidor/caché aislada; permitir visualizarlos y cambiarlos sin atribuir al usuario el centro inicial del mapa.
- FR-003: confirmar que la cuenta fue creada incluso si falla el inicio de sesión posterior; no repetir el alta ante un error de ubicación y mantener la pantalla hasta que la persona continúe.
- FR-004: Buscar aplica fondo, espaciados, campo, botón y cabecera aprobados; presenta datos reales o un estado pendiente explícito.

## 4. Requisitos no funcionales y datos
- NFR-001: errores visibles, privacidad de ubicación, atribución a OpenStreetMap/Photon, cancelación de respuestas obsoletas, límites de consulta y movimiento reducido.

## 5. Frontera y decisiones
La geocodificación y operaciones de ubicación siguen el [catálogo de operaciones backend](../../../API_NexoLocal/docs/endpoints.md) y sus [fichas](../../../API_NexoLocal/docs/contracts/fichas-operaciones.md). HTML de correo pertenece al backend y no se implementa en Flutter.

## 6. Aceptación local
- AC-001 → FR-001/NFR-001: dobles verifican búsqueda, selección y cancelación; las pruebas externas usan datos no personales y se distinguen de aceptación real.
- AC-002 → FR-002/FR-003/NFR-001: verificar aislamiento de cuenta, restauración de ubicación y éxito de alta ante fallo posterior de ubicación/login.
- AC-003 → FR-004/NFR-001: regresiones visuales y suites aprobadas; esto no equivale a aceptación humana total.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001 | AC-001 |
| FR-002 | T-001 | AC-001,AC-002 |
| FR-003 | T-002 | AC-002 |
| FR-004 | T-003 | AC-003 |
| NFR-001 | T-001,T-002,T-003 | AC-001,AC-002,AC-003 |

## Aprobación
Implementación local registrada; validación con servicio remoto y aceptación humana integral pendientes.
