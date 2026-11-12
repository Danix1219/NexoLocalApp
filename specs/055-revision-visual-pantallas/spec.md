# 055 — Revisión visual por pantalla y navegación única

Estado: Borrador documental; correcciones locales registradas; aceptación visual humana pendiente.

## 1. Contexto y alcance
La revisión parte de capturas donde Mi perfil duplica la barra inferior y algunos textos se perciben demasiado finos. Se registra la corrección por pantalla, manteniendo como referencia la maqueta aprobada y las rutas existentes.

## 2. Actores y precondiciones
Persona con sesión que consulta Cuenta, Mi perfil, edición, Inicio y Buscar. La revisión visual debe comparar pantallas completas en anchos de 390 y 320 píxeles.

## 3. Requisitos funcionales
- FR-001: cada ruta principal o detalle muestra una sola barra inferior y permite navegar entre perfil, edición y pantallas raíz.
- FR-002: las pantallas declaran pesos tipográficos estáticos y legibles de forma consistente.
- FR-003: portada, avatar, encabezados, listas, compositores y mensajes siguen las reglas visuales aprobadas.
- FR-004: Inicio y Buscar mantienen cabeceras relevantes al desplazarse, y la selección de ubicación se presenta como hoja cuando corresponde.

## 4. Requisitos no funcionales y datos
- NFR-001: conservar datos reales, verificación de correo y formularios; no inventar contenido pendiente y respetar movimiento reducido.

## 5. Frontera y decisiones
No se incorporan endpoints ni datos de demostración. Se conserva el alcance de [perfil profesional](../054-integracion-perfiles/spec.md). La auditoría registra las diferencias y límites en [revisión visual por pantalla](../../docs/revision-visual-pantallas.md).

## 6. Aceptación local
- AC-001 → FR-001/FR-004: Cuenta → Mi perfil → editar/volver conserva una sola barra y acciones visibles.
- AC-002 → FR-002/FR-003: comparación visual a 390 y 320 píxeles sin errores de layout y con fuentes cargadas.
- AC-003 → FR-001/FR-004/NFR-001: regresión de rutas principales y movimiento reducido; aprobación visual exhaustiva humana sigue pendiente.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-003 | AC-001,AC-003 |
| FR-002 | T-002 | AC-002 |
| FR-003 | T-002 | AC-002 |
| FR-004 | T-003 | AC-001,AC-003 |
| NFR-001 | T-003 | AC-003 |

## Aprobación
Correcciones locales registradas; aceptación visual humana exhaustiva pendiente.
