# PLAN — 004-identidad-sesion

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 003-contratos-consumo y nv-04 para integración real. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Implementar en diseño registro/login/renovación/logout: almacenamiento seguro, limpieza de cuenta y estado de cierre local/remoto; servidor valida OTP y sesión.

S01: accounts, otp_challenges, sessions y deletions; teléfono normalizado único, proofToken de un uso, refresh hash/familia, estado durable. App: nunca OTP/contraseña persistidos; no JWT eterno.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. Logout offline limpia acceso local y muestra revocación remota pendiente; recuperar contraseña invalida sesiones según política ratificada; refresh concurrente no crea bucles.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Ana sale y Carlos entra sin subir cola/borrador anterior; renovación concurrente usa una sola operación; logout offline muestra cierre local y estado remoto pendiente, sin conservar JWT de acceso general para cerrar después.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-001 | FR-201 → T-201 → AC-201 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Público limitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-002 | FR-202 → T-202 → AC-202 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Público con desafío; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-003 | FR-203 → T-203 → AC-203 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Público con prueba OTP; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-004 | FR-204 → T-204 → AC-204 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Público limitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-005 | FR-205 → T-205 → AC-205 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Poseedor de refresh; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-007 | FR-207 → T-207 → AC-207 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Cuenta autenticada; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-008 | FR-208 → T-208 → AC-208 | Consumidor de [nv-04](../../../API_NexoLocal/specs/nv-04/spec.md), actor Propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M02 Autenticación | FR-502 → T-502 → AC-502 | Origen maqueta auHTML, aunext; dependencia S01. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M03 Registro solicitante | FR-503 → T-503 → AC-503 | Origen maqueta newOb, obStep, obFinish; dependencia S01/S02/S06. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| R10 Logout | FR-410 → T-410 → AC-410 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H03

FR-703 → T-703 → AC-703: Ana publica/guarda y sale; Carlos no recibe como propia autoría, borrador, cola o caché de Ana; IDs del token, nunca Tú/me. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
