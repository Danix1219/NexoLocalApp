# PLAN — 023-privacidad-permisos-enlaces

[Spec](spec.md), [tareas](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Solo cuatro documentos actuales; futuras capas/presentación/repositorio/adaptadores se concretan al encargar sin crear lib/pubspec.

## 2. Contratos (rutas, config, env)

[Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Solo consumo público/autenticado definido, sin copiar payload.

## 3. Cambios por archivo (qué y por qué)

Aviso/consentimiento, permisos Android en contexto y compartir/copiar/ruta autorizados. Vista/VM/repositorio: carga, vacío, error, offline, accesibilidad y navegación según acción.

## 4. Tests por requisito FR/NFR

Permiso denegado ofrece alternativa; compartir no incluye PII; deep link no revela domicilio revocado. Separar doble/widget de API real/SQLite/dispositivo.

## 5. Gates

Lint hoy; analyze/unit/widget/integration con rutas/SDK reales al implementar.

## 6. Riesgos y deudas documentadas

No endpoint por control local ni permisos indiscriminados; destino vuelve a autorizar. D02/D04/D05 pertinentes pendientes.

## 7. Orden de implementación

T-006/T-020 → T-001 → T-002 → T-010..012/T-021 y consumo EP → T-003/T-004 → T-007/T-005.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M24 Privacidad y sesión | FR-524 → T-524 → AC-524 | Origen maqueta privacySheet, delSheet, logoutSheet; dependencia S01/S07. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M27 Compartir, copiar y ruta | FR-527 → T-527 → AC-527 | Origen maqueta share, copy, directions, mroute; dependencia Sistema Android/S02/S04. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| R16 Móvil completo | FR-416 → T-416 → AC-416 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
