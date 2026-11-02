# PLAN — 020-experiencias-reputacion

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-19/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Experiencia declarada/vinculada, estrellas, mención reactiva, edición y retiro. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Quitar mención actualiza diálogo/formulario; sin elegibilidad no muestra pedido registrado; retirar refresca resumen. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Una mención; registeredOrder ligado a pedido; EP-095 no supone nueva pantalla confirmada. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-041 | FR-241 → T-241 → AC-241 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Cuenta; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-042 | FR-242 → T-242 → AC-242 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Público; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-043 | FR-243 → T-243 → AC-243 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Autor; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-044 | FR-244 → T-244 → AC-244 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Autor o moderador; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-093 | FR-293 → T-293 → AC-293 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Cuenta autenticada; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-094 | FR-294 → T-294 → AC-294 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Autor autenticado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-095 | FR-295 → T-295 → AC-295 | Consumidor de [nv-19](../../../API_NexoLocal/specs/nv-19/spec.md), actor Público o autor según estado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M15 Experiencia y estrellas | FR-515 → T-515 → AC-515 | Origen maqueta publishexp, expstar, mreview; dependencia S03/S04/S06. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H04

FR-704 → T-704 → AC-704: Quitar/cambiar prestador actualiza relación estructurada, chip y diálogo; registeredOrder no cambia destinatario fuera del pedido. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
