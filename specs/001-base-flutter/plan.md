# PLAN — 001-base-flutter

Spec: [spec.md](spec.md). Tareas: [tasks.md](tasks.md). Estado: diseño, sin app creada.

## 1. árbol objetivo (archivos a crear/modificar)

Documentos existentes: spec.md, plan.md, tasks.md y checklist.md. Futuro: feature con presentación, aplicación y adaptadores remoto/local; concretar nombres/rutas al encargar código. No crear lib, pubspec ni tests en esta fase.

## 2. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md) y [acuerdo](../../../docs_nexo/SDD_ALINEACION.md). Dependencias: Ninguna; leer gobierno API nv-00 y acuerdos comunes. Seleccionar EP por historia; no acceder a operaciones internas/admin ni bases del servidor.

## 3. Cambios por archivo (qué y por qué)

Definir M01/M05/M26: navegación visitante/cuenta, cambio de modo, tema y estados comunes; seleccionar arquitectura Flutter y almacenamiento por cuenta.

API: inventario de bases por servicio y configuración sin secretos. App: zona pública, preferencias, sesión y caché privada separadas; token fuera de SQLite.

Vista presenta estados; ViewModel procesa intención; repositorio decide remoto/local sin convertir datos antiguos en permisos. Definir carga, éxito, vacío, error, offline, sesión expirada y conflicto según aplique. Reusar navegación M05 y accesibilidad M26; no imponer librería de estado todavía.

## 4. Tests por requisito FR/NFR

FR-090→T-006/T-007→AC-090. Documentar arranque, configuración faltante y fallo de dependencia sin afirmar proyecto creado; app conserva selección manual si GPS se deniega.

Además de las AC existentes, probar semántica/lector, texto escalado, foco/touch y retorno desde permiso denegado cuando aplique. Integración real espera el contrato del proveedor; doble y test de widget no acreditan Android/backend.

## 5. Gates

[Roles y gates](../../docs/roles-y-gates.md). Hoy solo scripts/check_sdd.ps1. Analyze/unit/widget/integration/dispositivo se definen con rutas y SDK reales después de encargo. Evidencia por requisito, sin copiar comandos de Razor ni scripts Node.

## 6. Riesgos y deudas documentadas

D02/D04/D05/D06/D07 pertinentes siguen por ratificar. Ausencia de GPS/push/red requiere alternativa visible; no simular acción de contraparte. Contrato/proveedor/modelo por confirmar no pasa integración.

## 7. Orden de implementación

T-006 refina antes de T-001 Ready; T-002/T-003 construcción/integración solo por encargo; T-004 privacidad; T-007 verifica AC-090; T-005 concilia documentos y evidencia. Un traspaso Codex/Claude se registra en Memoria y continúa secuencialmente.

## Integridad constitucional y orden de tareas

T-006/T-020 refinan FR-090/FR-100 y decisiones antes de T-001. T-002 prepara el cambio; T-010 y siguientes atienden cada FR principal; T-021 comprueba AC-100. T-003 integra, T-004 revisa seguridad, T-007 comprueba AC-090 y T-005 cierra. [Tareas](tasks.md) y tabla de trazabilidad en [spec](spec.md) son autoridad de IDs/dependencias; este orden prevalece sobre resúmenes anteriores.

AC-100: Visitante vuelve sin perder zona; deep link protegido retoma intención tras login sin dar permisos por modo; lector/texto escalado y controles de 48 dp se verifican en dispositivo al implementar.

Tipo de evidencia: documental hoy; al implementar, unitario con doble separado de contrato/integración real y, en móvil, dispositivo. Sin comandos de producto válidos mientras no existan proyectos.

## Desglose de funciones y obligaciones

| Fuente | Historia/tarea/criterio | Diseño y prueba |
|---|---|---|
| M01 Bienvenida y guía | FR-501 → T-501 → AC-501 | Origen maqueta start, GTOUR, welcome; dependencia S02; estado local. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M05 Navegación principal | FR-505 → T-505 → AC-505 | Origen maqueta render, go, ACT.tab; dependencia go_router propuesto. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| M26 Diseño compartido y estado | FR-526 → T-526 → AC-526 | Origen maqueta CSS y funciones compartidas; dependencia Flutter UI/SQLite. Separar UI local de acción remota; enlazar EP del recorrido y no crear operación por control. |
| R03 Cinco componentes del proyecto | FR-403 → T-403 → AC-403 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |
| R04 Correspondencia con maqueta | FR-404 → T-404 → AC-404 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |
| R06 Desarrollo con agentes | FR-406 → T-406 → AC-406 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |
| R11 Matriz de versiones | FR-411 → T-411 → AC-411 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |
| R18 GitHub/coordinación | FR-418 → T-418 → AC-418 | Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. |
| PRE1 Entrevistas | FR-451 → T-451 → AC-451 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |
| PRE2 Descripciones separadas | FR-452 → T-452 → AC-452 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |
| PRE3 Componentes en hoja de cálculo | FR-453 → T-453 → AC-453 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |
| PRE4 CRUD y funciones por endpoint | FR-454 → T-454 → AC-454 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |
| PRE5 Referencias docentes | FR-455 → T-455 → AC-455 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |
| PRE6 Estructura SDD | FR-456 → T-456 → AC-456 | Fuente: lineamientos Móvil v2, página 4. Artefacto común no se duplica como dos entrevistas o dos hojas incompatibles. |

## Orden y frontera vigentes 0.4.0

Cada operación/función/obligación desglosada tiene requisito, tarea y AC en la spec. T-003 espera también esas tareas, no solo el bloque base. La tarea concreta se refina con contrato/revisión, decisión bloqueante y rutas reales antes de ejecutar; no construir todas las historias de una fase de una vez. [Cobertura bilateral](../../../docs_nexo/SDD_COBERTURA_FUNCIONAL.md) indica primario, integración, opcional o superficie excluida.
