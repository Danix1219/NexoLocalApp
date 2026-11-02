# PLAN — 022-push-dispositivos

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-21/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Solicitar permiso en contexto, asociar por sesión y abrir avisos con revalidación. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Denegar push conserva bandeja; aviso antiguo no abre recurso revocado; logout desvincula token. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Push sin teléfono/domicilio/texto privado; bandeja disponible sin permiso. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-083 | FR-283 → T-283 → AC-283 | Consumidor de [nv-21](../../../API_NexoLocal/specs/nv-21/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-084 | FR-284 → T-284 → AC-284 | Consumidor de [nv-21](../../../API_NexoLocal/specs/nv-21/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-085 | FR-285 → T-285 → AC-285 | Consumidor de [nv-21](../../../API_NexoLocal/specs/nv-21/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-086 | FR-286 → T-286 → AC-286 | Consumidor de [nv-21](../../../API_NexoLocal/specs/nv-21/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M22 Notificaciones | FR-522 → T-522 → AC-522 | Origen maqueta notifSheet, bell; dependencia S07/FCM. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
