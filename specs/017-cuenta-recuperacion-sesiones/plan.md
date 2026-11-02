# PLAN — 017-cuenta-recuperacion-sesiones

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-16/spec.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Recuperación real, edición de cuenta y sesiones con confirmación y errores neutrales. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Recovery inválido no confirma éxito; dispositivo revocado deja de operar; lista propia no muestra secretos. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

Identidad real; no contraseña/OTP en SQLite. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-006 | FR-206 → T-206 → AC-206 | Consumidor de [nv-16](../../../API_NexoLocal/specs/nv-16/spec.md), actor Prueba OTP recovery; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-009 | FR-209 → T-209 → AC-209 | Consumidor de [nv-16](../../../API_NexoLocal/specs/nv-16/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-010 | FR-210 → T-210 → AC-210 | Consumidor de [nv-16](../../../API_NexoLocal/specs/nv-16/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-011 | FR-211 → T-211 → AC-211 | Consumidor de [nv-16](../../../API_NexoLocal/specs/nv-16/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
