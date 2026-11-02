# PLAN — 009-solicitudes

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 006-perfiles, 005-contenido-seguro y nv-09. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar publicar/buscar solicitudes, expresar/retirar interés y consultar interesados propios; filtros de coincidencia y urgencia independientes.

S04: requests/interests, único requestId/providerId; estado y propietario, urgencies=Hoy diferente de createdToday; no teléfono/domicilio en lectura pública.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. H12: urgencia Hoy incluye publicación anterior; un prestador puede interesarse fuera de categoría coincidente si visibilidad/estado lo permiten; shortlist no bloquea aceptación.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Hoy muestra urgencia aunque la publicación sea anterior; propia/cerrada no ofrece interés; otro usuario no abre interesados; shortlist no se añade a aceptación obligatoria.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-047 | FR-247 → T-247 → AC-247 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Solicitante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-048 | FR-248 → T-248 → AC-248 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Prestador o visitante público limitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-049 | FR-249 → T-249 → AC-249 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Público o propietario según campos; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-050 | FR-250 → T-250 → AC-250 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-051 | FR-251 → T-251 → AC-251 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-052 | FR-252 → T-252 → AC-252 | Consumidor de [nv-09](../../../API_NexoLocal/specs/nv-09/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M09 Buscar solicitudes | FR-509 → T-509 → AC-509 | Origen maqueta V.search, reqHTML; dependencia S04/S02. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M13 Publicar necesidad | FR-513 → T-513 → AC-513 | Origen maqueta pubReq, publishreq; dependencia S04/S06/ML. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H12

FR-712 → T-712 → AC-712: Tres precios, seis fotos portafolio/cuatro por trabajo se conservan en sus dueños; urgencia Hoy no es fecha de creación y shortlist sigue opcional. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
