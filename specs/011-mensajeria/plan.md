# PLAN — 011-mensajeria

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 010-pedidos, 005-contenido-seguro y nv-11. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar bandeja, texto/foto/respuesta rápida, pendiente/confirmado/fallo y recuperación por cursor al reconectar.

S05: conversations/messages/blocks; unique conversationId/clientMessageId, sequence durable y contexto requestId/orderId por mensaje; Redis Pub/Sub no historial. WS no lleva JWT en URL persistible.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. H05/H11: texto rápido/manual utiliza misma intención; reintento mismo ID da una entrega; nuevo pedido cambia cabecera sin reescribir mensajes; logout invalida conexión existente.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Respuesta rápida no se sobrescribe por campo vacío; mismo ID produce una burbuja confirmada; nuevo pedido no altera mensajes anteriores; logout corta WS y evita reenvío de otra cuenta.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-066 | FR-266 → T-266 → AC-266 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Cliente o prestador habilitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-067 | FR-267 → T-267 → AC-267 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Participante; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-068 | FR-268 → T-268 → AC-268 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Miembro; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-069 | FR-269 → T-269 → AC-269 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Miembro sin bloqueo; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-070 | FR-270 → T-270 → AC-270 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Miembro; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-071 | FR-271 → T-271 → AC-271 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Miembro; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-072 | FR-272 → T-272 → AC-272 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Autor del bloqueo; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-073 | FR-273 → T-273 → AC-273 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Cuenta autenticada; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-074 | FR-274 → T-274 → AC-274 | Consumidor de [nv-11](../../../API_NexoLocal/specs/nv-11/spec.md), actor Ticket y membresía vigentes; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M18 Bandeja de mensajes | FR-518 → T-518 → AC-518 | Origen maqueta V.inbox, unreadAll; dependencia S05. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M19 Chat | FR-519 → T-519 → AC-519 | Origen maqueta V.chat, msgsend, chatblock; dependencia S05/S06/S04. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H05

FR-705 → T-705 → AC-705: Respuesta rápida y manual usan la misma intención; texto elegido no se sobrescribe por campo vacío y reintento no duplica. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.

### Regresión H11

FR-711 → T-711 → AC-711: Nueva orden no reescribe contexto histórico; mensaje/evento tiene orderId/requestId autorizado y cabecera muestra pedido activo. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
