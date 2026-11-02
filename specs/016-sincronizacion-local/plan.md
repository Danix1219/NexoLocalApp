# PLAN — 016-sincronizacion-local

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Solo diseño.

## 1. Árbol objetivo (archivos a crear/modificar)

Existen estos cuatro documentos. El futuro repositorio local, migraciones y trabajador de sincronización se ubican en capa de datos compartida o feature según D02; nombres/rutas reales se fijan al encargar código. No se crean lib/pubspec/scripts/tests ahora.

## 2. Contratos (rutas, config, env)

Seleccionar lecturas y guardados de la spec, enlazar revisión formal API. Cola con operationId, userId, versión base, estado, intentos y próxima ejecución propuestos; límites/protección/retención pendientes. No almacenar token en payload.

## 3. Cambios por archivo (qué y por qué)

Vista muestra local/antiguo/pendiente; ViewModel cancela intenciones al salir; repositorio aplica allowlist y exige sesión vigente para sincronizar; adaptador SQLite mantiene atomicidad local y migración recuperable. Sincronización se pausa ante falta de red, credencial revocada o cambio de cuenta. Respuestas se descartan cuando no coinciden cuenta/época de sesión/contexto actuales.

## 4. Tests por requisito FR/NFR

Pruebas con doble para política/estados; SQLite real para migración/atomicidad; API real para idempotencia/conflictos; dispositivo para cierre de proceso y aislamiento. AC-001..006/090/100 tienen tareas y matriz de trazabilidad.

## 5. Gates

Hoy scripts/check_sdd.ps1 y revisión documental adicional. Al implementar fijar comandos/rutas de analyze, unit/widget, SQLite y Android; no llamar integración a una colección en memoria.

## 6. Riesgos y deudas documentadas

D02/D05, contrato por operación y escenarios de pérdida/interrupción pendientes. Excluir acciones críticas offline. Una migración fallida necesita recuperación explícita y aviso, nunca borrado indiscriminado.

## 7. Orden de implementación

Refinar allowlist/esquema/decisiones → Ready de historia → encargo de implementación → lecturas locales → guardados/cola → migración/conflictos/cambio de cuenta → integración real → evidencia y revisión. La consulta local mínima puede avanzar sin esperar todos los dominios.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Una respuesta que llega después de logout/cancelación/cambio de cuenta no repuebla caché privada ni inicia reenvío de sesión anterior.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| R09 Caché en tres niveles | FR-409 → T-409 → AC-409 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
