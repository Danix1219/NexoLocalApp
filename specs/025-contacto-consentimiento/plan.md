# PLAN — 025-contacto-consentimiento

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-25/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Mostrar preferencias y permiso por pedido; retirar datos/copia/ruta al revocar. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Revocar showPhone/both retira dato; pendiente/cancelado no muestra contacto; fallo de política no concede permiso. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Dato recibido autorizado; no teléfono en caché pública; wa legacy significa chat interno. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-091 | FR-291 → T-291 → AC-291 | Consumidor de [nv-25](../../../API_NexoLocal/specs/nv-25/spec.md), actor Cuenta autenticada; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-092 | FR-292 → T-292 → AC-292 | Consumidor de [nv-25](../../../API_NexoLocal/specs/nv-25/spec.md), actor Participante habilitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-096 | FR-296 → T-296 → AC-296 | Consumidor de [nv-25](../../../API_NexoLocal/specs/nv-25/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-097 | FR-297 → T-297 → AC-297 | Consumidor de [nv-25](../../../API_NexoLocal/specs/nv-25/spec.md), actor Cliente propietario del pedido; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H01

FR-701 → T-701 → AC-701: Participante prestador obtiene teléfono cliente solo en ok/done y both vigente; dato no existe en DTO ni copia no autorizados. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
