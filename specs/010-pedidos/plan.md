# PLAN — 010-pedidos

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 009-solicitudes, 006-perfiles y nv-10; entrada chat se completa con 011-mensajeria. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar envío, aceptar/rechazar/cancelar/resolver y cambio de domicilio; datos sensibles, copia y ruta dependen del permiso vigente recibido.

S04: orders y referencia de asignación en requests; version, participante, precio informativo. pend→ok/cancel; ok→done/cancel. Rechazo se representa con cancel y razón ratificada; done/cancel terminales.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. H01/H02: pendiente/rechazado no expone teléfono/domicilio; cancelar retira también caché/rutas; dos aceptaciones simultáneas dejan solo una asignación activa.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Pendiente/rechazado no muestra teléfono/dirección precisa; cancelar elimina información privada visible/local; conflicto refresca sin doble aceptación; no se aceptan/resuelven pedidos offline.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-058 | FR-258 → T-258 → AC-258 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Solicitante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-059 | FR-259 → T-259 → AC-259 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Participante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-060 | FR-260 → T-260 → AC-260 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Participante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-061 | FR-261 → T-261 → AC-261 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Prestador destinatario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-062 | FR-262 → T-262 → AC-262 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Prestador destinatario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-063 | FR-263 → T-263 → AC-263 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Cliente o prestador participante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-064 | FR-264 → T-264 → AC-264 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Prestador destinatario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-065 | FR-265 → T-265 → AC-265 | Consumidor de [nv-10](../../../API_NexoLocal/specs/nv-10/spec.md), actor Cliente del pedido; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M17 Pedido | FR-517 → T-517 → AC-517 | Origen maqueta agSheet, V.match; dependencia S04/S05. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H02

FR-702 → T-702 → AC-702: Cancel/rechazo retira dirección precisa, caché y ruta; solo zona pública permanece. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
