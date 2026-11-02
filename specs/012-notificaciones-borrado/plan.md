# PLAN — 012-notificaciones-borrado

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 004-identidad-sesion para inicio; 005..011 para cierre integrado; nv-12. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar permiso push, rutas autorizadas, bandeja sin push y eliminación con reautenticación, purga local y progreso hasta confirmación.

S07: devices/notifications/deliveries; S01 deletions y acuses de cada servicio habilitado. Dedupe por eventId/destinatario; tombstones impiden reaparición. Retención/backups requieren decisión explícita.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. Push a sesión anterior no entrega datos de nueva cuenta; borrado parcial no informa completado; cuenta bloqueada de inmediato; restaurar backup aplica supresiones antes de servir.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Push de cuenta anterior no revela contenido; destino cancelado no abre domicilio; sin permiso existe bandeja; trámite parcial se mantiene pendiente y no puede reaparecer cola privada borrada.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-012 | FR-212 → T-212 → AC-212 | Consumidor de [nv-12](../../../API_NexoLocal/specs/nv-12/spec.md), actor Propietario reautenticado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-013 | FR-213 → T-213 → AC-213 | Consumidor de [nv-12](../../../API_NexoLocal/specs/nv-12/spec.md), actor Credencial limitada al trámite; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
