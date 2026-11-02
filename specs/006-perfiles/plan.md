# PLAN — 006-perfiles

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 004-identidad-sesion, 005-contenido-seguro y nv-06. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar alta básica y edición posterior con opcionales omitibles, selector geográfico y resumen de completitud recibido del backend.

S02: categories, providers y read_cache; perfil por cuenta único, GeoJSON [longitud,latitud], origen privado y dirección comercial explícita. Límites: tres precios y seis fotos de portafolio.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. H06/H07/H09/H10: mismo porcentaje/policyVersion en alta y perfil, fotos no cuentan como trabajos, radio cero solo local y edición siempre accesible.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Alta básica no exige foto/horario/precio opcionales; editar después sigue accesible; solo local no anuncia cobertura a domicilio; tres precios y seis fotos se validan sin contar fotos como trabajos.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-016 | FR-216 → T-216 → AC-216 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Cuenta sin perfil; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-017 | FR-217 → T-217 → AC-217 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Público; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-018 | FR-218 → T-218 → AC-218 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-019 | FR-219 → T-219 → AC-219 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-020 | FR-220 → T-220 → AC-220 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-021 | FR-221 → T-221 → AC-221 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-022 | FR-222 → T-222 → AC-222 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-023 | FR-223 → T-223 → AC-223 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador propietario; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-024 | FR-224 → T-224 → AC-224 | Consumidor de [nv-06](../../../API_NexoLocal/specs/nv-06/spec.md), actor Prestador reautenticado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M04 Registro prestador | FR-504 → T-504 → AC-504 | Origen maqueta buildProvider, svcadd, obbasic; dependencia S01/S02/S06. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M11 Perfil público | FR-511 → T-511 → AC-511 | Origen maqueta V.profile, trustSheet; dependencia S02/S03/S05. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M21 Cuenta y edición | FR-521 → T-521 → AC-521 | Origen maqueta V.account, edSheet, profileTodo; dependencia S01/S02/S03. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H06

FR-706 → T-706 → AC-706: Alta/perfil/cuenta reciben la misma política versionada sobre los mismos datos; fórmula por ratificar sin porcentajes inventados. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.

### Regresión H07

FR-707 → T-707 → AC-707: Fotos de portafolio, publicaciones, pedidos resueltos y recomendaciones son contadores distintos; seis fotos no equivalen a seis servicios. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.

### Regresión H09

FR-709 → T-709 → AC-709: Tras completar horario/precios/condiciones/contacto se conserva acceso a editar y respuesta actualiza vistas/caché. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.

### Regresión H10

FR-710 → T-710 → AC-710: Radio cero en local no vuelve invisible negocio ni muestra menos de 0 km a domicilio; selector y búsqueda respetan modalidad. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
