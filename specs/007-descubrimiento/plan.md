# PLAN — 007-descubrimiento

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: 006-perfiles; feed ampliado se integra con 008-comunidad y nv-07. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Diseñar visitante, búsqueda/mapa, comparación máxima de dos, estados vacíos y caché pública con antigüedad visible; acciones protegidas retoman tras registro.

S02/G01: filtros normalizados, read_cache con expiresAt comprobado por lector, cursor estable y DTO público. App: recientes y resúmenes públicos; no origen privado ni contactos cacheados.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. H08/H10: comparar solo serviceKey/unidad/moneda/materiales; local con radio cero aparece; denegar GPS conserva entrada manual; edición invalida caché entre réplicas.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Denegar GPS no bloquea explorar; dato local muestra antigüedad y refresco; solo se muestra mejor precio si comparable=true con conceptos equivalentes; contacto privado no vive en caché pública.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Cobertura por operación propia

| EP | Requisito/tarea/AC | Diseño y comprobación |
|---|---|---|
| EP-025 | FR-225 → T-225 → AC-225 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Público; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-026 | FR-226 → T-226 → AC-226 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Público; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-027 | FR-227 → T-227 → AC-227 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Cuenta autenticada; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-028 | FR-228 → T-228 → AC-228 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Público limitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-029 | FR-229 → T-229 → AC-229 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Público limitado; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |
| EP-030 | FR-230 → T-230 → AC-230 | Consumidor de [nv-07](../../../API_NexoLocal/specs/nv-07/spec.md), actor Público o cuenta según filtro; contrato por formalizar. Widget/doble verifica estado; API real confirma regla, permiso y reintento; Android verifica sistema si aplica. |

No copiar payloads en app: [inventario](../../../API_NexoLocal/docs/contracts/inventario.json). Cada tarea se refina antes de Ready con contrato exacto y rutas reales al encargar código.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M06 Inicio solicitante | FR-506 → T-506 → AC-506 | Origen maqueta V.home, htab; dependencia Gateway/S02/S03/S04. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M07 Inicio prestador | FR-507 → T-507 → AC-507 | Origen maqueta V.home, provPendHTML; dependencia S02/S04. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M08 Buscar prestadores | FR-508 → T-508 → AC-508 | Origen maqueta V.search, resultsHTML, filterSheet; dependencia S02. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M10 Selector geográfico | FR-510 → T-510 → AC-510 | Origen maqueta pickerOpen, mapfind, mapgps; dependencia S02/Mapas/permisos. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M12 Comparación | FR-512 → T-512 → AC-512 | Origen maqueta V.compare, cmp; dependencia S02. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.

### Regresión H08

FR-708 → T-708 → AC-708: Precio menor solo se destaca con servicio, unidad, moneda, alcance/materiales equivalentes; si falta dato, no comparable con razón. Fuente: auditoría 1.2.0; prueba nueva de producto pendiente.
