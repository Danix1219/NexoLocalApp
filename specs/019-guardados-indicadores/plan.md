# PLAN — 019-guardados-indicadores

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-18/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Presentar guardados/reacciones y métricas propias sin duplicar al sincronizar. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Guardar/quitar repetido deja estado canónico; cambio de cuenta no muestra lista ni métricas ajenas. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Datos particionados; recurso retirado no se muestra como vigente; clic no es trabajo. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-036 | FR-236 → T-236 → AC-236 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Cuenta; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-037 | FR-237 → T-237 → AC-237 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Autor de reacción; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-038 | FR-238 → T-238 → AC-238 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-039 | FR-239 → T-239 → AC-239 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-040 | FR-240 → T-240 → AC-240 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-045 | FR-245 → T-245 → AC-245 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Público limitado o cuenta; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-046 | FR-246 → T-246 → AC-246 | Consumidor de [nv-18](../../../API_NexoLocal/specs/nv-18/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M20 Guardados | FR-520 → T-520 → AC-520 | Origen maqueta V.saved, savep, savew, saver; dependencia S03/SQLite. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
