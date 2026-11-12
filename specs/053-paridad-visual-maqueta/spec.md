# 053 — Paridad visual con la maqueta desplegada

Estado: Borrador documental; implementación local registrada por separado; aceptación visual humana pendiente.

## 1. Contexto y alcance
La referencia visual examinada en Chrome es https://nexo-local-v1.netlify.app/ (2026-11-09). Se mantienen Flutter, Riverpod, Dio y correo real.

## 2. Actores y precondiciones
Personas usuarias de acceso, registro, Inicio, Buscar, Publicar, Cuenta, perfiles, solicitudes, pedidos, mensajes y hojas. No se habilitan endpoints pendientes ni contadores de demostración.

## 3. Requisitos funcionales
- FR-001: entradas de pantalla usan transición breve de opacidad y desplazamiento, con movimiento reducido respetado.
- FR-002: pulsaciones muestran respuesta visual breve, respetan movimiento reducido y preservan foco y acciones.
- FR-003: barra inferior mantiene iconos, área táctil, estilo de selección y badge derivado de datos reales.
- FR-004: Mi perfil presenta portada, avatar, identidad, estadísticas reales o pendientes, acciones y pestañas.
- FR-005: subpantallas de perfil, guardados, comparación, interesados y pedido mantienen acceso a navegación; chat, mapa y formularios no muestran barra raíz.

## 4. Requisitos no funcionales y datos
- NFR-001: cambio de pestañas conserva borradores y posición; los errores no se animan como datos nuevos.

## 5. Frontera y decisiones
Sin cambios de API. Correo verificado sustituye el celular confirmado del prototipo. Fotos y experiencias pendientes se presentan sin simular guardado. Evidencia visual y sus límites constan en [paridad visual](../../docs/paridad-visual-maqueta.md).

## 6. Criterios de aceptación
- AC-001 → FR-001/FR-002/NFR-001: widgets verifican pulsación, cancelación, movimiento reducido y conservación de estado.
- AC-002 → FR-003/FR-004/FR-005: barra y perfil usan datos reales, mantienen acciones y presentan navegación apropiada.
- AC-003 → FR-001/FR-002/FR-003/FR-004/FR-005/NFR-001: pruebas y APK se registran; revisión visual en dispositivo queda identificada como pendiente cuando no se realiza.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-004 | AC-001,AC-003 |
| FR-002 | T-001,T-004 | AC-001,AC-003 |
| FR-003 | T-002,T-004 | AC-002,AC-003 |
| FR-004 | T-003,T-004 | AC-002,AC-003 |
| FR-005 | T-002,T-004 | AC-002,AC-003 |
| NFR-001 | T-001,T-004 | AC-001,AC-003 |

## Aprobación
Implementación local con evidencia técnica registrada; revisión visual humana exhaustiva pendiente.
