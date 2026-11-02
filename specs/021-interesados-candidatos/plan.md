# PLAN — 021-interesados-candidatos

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-20/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Expresar/retirar interés, consultar interesados propios y pedir desde candidato. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Otro usuario no accede a interesados; fuera de categoría visible no se bloquea arbitrariamente. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Shortlist opcional; filtro y modo no conceden permiso. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-053 | FR-253 → T-253 → AC-253 | Consumidor de [nv-20](../../../API_NexoLocal/specs/nv-20/spec.md), actor Prestador; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-054 | FR-254 → T-254 → AC-254 | Consumidor de [nv-20](../../../API_NexoLocal/specs/nv-20/spec.md), actor Prestador interesado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-055 | FR-255 → T-255 → AC-255 | Consumidor de [nv-20](../../../API_NexoLocal/specs/nv-20/spec.md), actor Dueño de solicitud; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-056 | FR-256 → T-256 → AC-256 | Consumidor de [nv-20](../../../API_NexoLocal/specs/nv-20/spec.md), actor Dueño de solicitud; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-057 | FR-257 → T-257 → AC-257 | Consumidor de [nv-20](../../../API_NexoLocal/specs/nv-20/spec.md), actor Dueño de solicitud; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M16 Mis solicitudes e interesados | FR-516 → T-516 → AC-516 | Origen maqueta V.myprofile, V.ints, reqshort; dependencia S04/S02/S03. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
