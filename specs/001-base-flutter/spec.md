# 001-BASE-FLUTTER — Fundación y navegación Flutter

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `001-base-flutter`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/3/4/6/8; D02.

Fase de fundamento previa a funcionalidad. Conserva el orden de aprendizaje del profesor sin copiar infraestructura incompatible.

## 2. Objetivo

Fundación y navegación Flutter

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: SDD, calidad, contratos y entrega; no reemplaza el alcance de funcionalidades.

Dependencias: Ninguna; leer gobierno API nv-00 y acuerdos comunes.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Definir navegación M05 y accesibilidad M26 con pila/retorno, deep links revalidados, carga/vacío/error, foco/semántica, texto escalado y controles táctiles.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Sin producto ni proveedor simulado presentado como real.
- Contratos/plantillas y configuración no deben contradecir la constitución.

- FR-090: Definir M01/M05/M26: navegación visitante/cuenta, cambio de modo, tema y estados comunes; seleccionar arquitectura Flutter y almacenamiento por cuenta.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Documentar arranque, configuración faltante y fallo de dependencia sin afirmar proyecto creado; app conserva selección manual si GPS se deniega.

- FR-100: Definir navegación M05 y accesibilidad M26 con pila/retorno, deep links revalidados, carga/vacío/error, foco/semántica, texto escalado y controles táctiles.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/3/4/6/8; D02.

### Funcionalidades y obligaciones con dueño explícito

- FR-501: M01 Bienvenida y guía: Actor Visitante: Marca, acciones buscar/ofrecer, recorrido contextual y selección inicial de zona.
- FR-505: M05 Navegación principal: Actor Ambos modos: Inicio, Buscar, Publicar, Mensajes y Cuenta; pila de subpantallas y enlaces profundos.
- FR-526: M26 Diseño compartido y estado: Actor Todos: Botones, formularios, chips, hojas, toast, skeleton, vacío/error/offline y Semantics.
- FR-403: R03 Cinco componentes del proyecto: Atender el requisito académico 3 en su superficie y coordinar la contraparte.
- FR-404: R04 Correspondencia con maqueta: Atender el requisito académico 4 en su superficie y coordinar la contraparte.
- FR-406: R06 Desarrollo con agentes: Atender el requisito académico 6 en su superficie y coordinar la contraparte.
- FR-411: R11 Matriz de versiones: Atender el requisito académico 11 en su superficie y coordinar la contraparte.
- FR-418: R18 GitHub/coordinación: Atender el requisito académico 18 en su superficie y coordinar la contraparte.
- FR-451: PRE1 Entrevistas: Preparar tarea previa 1 y conciliarla con el otro contexto.
- FR-452: PRE2 Descripciones separadas: Preparar tarea previa 2 y conciliarla con el otro contexto.
- FR-453: PRE3 Componentes en hoja de cálculo: Preparar tarea previa 3 y conciliarla con el otro contexto.
- FR-454: PRE4 CRUD y funciones por endpoint: Preparar tarea previa 4 y conciliarla con el otro contexto.
- FR-455: PRE5 Referencias docentes: Preparar tarea previa 5 y conciliarla con el otro contexto.
- FR-456: PRE6 Estructura SDD: Preparar tarea previa 6 y conciliarla con el otro contexto.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md).

API: inventario de bases por servicio y configuración sin secretos. App: zona pública, preferencias, sesión y caché privada separadas; token fuera de SQLite.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Documentos y límites coherentes con la constitución; lint documental sin referencias rotas.
- [ ] AC-002: Cuando se implemente esta fase, comandos y rutas reales constan en plan y evidencia; sin verdes prestados del profesor.

- [ ] AC-090 → FR-090/NFR-090: Documentar arranque, configuración faltante y fallo de dependencia sin afirmar proyecto creado; app conserva selección manual si GPS se deniega.

- [ ] AC-100 → FR-100/NFR-100: Visitante vuelve sin perder zona; deep link protegido retoma intención tras login sin dar permisos por modo; lector/texto escalado y controles de 48 dp se verifican en dispositivo al implementar.

- [ ] AC-501 → FR-501/NFR-002/NFR-003: Explorar sin cuenta y retomar contacto tras registro. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-505 → FR-505/NFR-002/NFR-003: Atrás coherente y estado separado por modo. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-526 → FR-526/NFR-002/NFR-003: Texto escalable, contraste y objetivos de 48 dp. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-403 → FR-403/NFR-002/NFR-003: Inventariar nube, bases de datos, backend, móvil y landing con propietario, versión e integración. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-404 → FR-404/NFR-002/NFR-003: Cubrir todos los M01–M27/W01 de la línea base y corregir H01–H12, sin eliminar funciones visibles ni promover simulaciones. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-406 → FR-406/NFR-002/NFR-003: Usar Codex/Claude Code con contexto, cambios acotados, bitácora de intervención real y revisión humana; las herramientas respetan la misma constitucion y autoridad de contratos. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-411 → FR-411/NFR-002/NFR-003: Definir antes del desarrollo versiones de servicios/API/contratos/eventos/datos/app/landing/infra y manifiesto por despliegue. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-418 → FR-418/NFR-002/NFR-003: Cuenta GitHub única del proyecto y carpeta compartida; registrar accesos y responsables. Correo de proyecto recomendado, sin compartir secretos. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-451 → FR-451/NFR-002/NFR-003: Entrevistas reales con consentimiento, evidencia y síntesis; definir cambios de alcance sin inventar participantes.
- [ ] AC-452 → FR-452/NFR-002/NFR-003: Descripción detallada en español del backend y móvil con funciones, actores y límites por contexto.
- [ ] AC-453 → FR-453/NFR-002/NFR-003: Conciliar 13 componentes backend y 27 móviles del libro, con responsabilidad, dependencia y aceptación.
- [ ] AC-454 → FR-454/NFR-002/NFR-003: Conciliar las 101 fichas: entradas/salidas/reglas, documentos NoSQL, llaves/índices y filtros/búsquedas, sin operación inventada por botón.
- [ ] AC-455 → FR-455/NFR-002/NFR-003: Registrar URLs/commit reales de proyectos docentes y comparación justificada; mientras falten, mantener pendiente sin simular revisión nueva.
- [ ] AC-456 → FR-456/NFR-002/NFR-003: Constituciones, secuencia docente, roles Codex/Claude, memoria, contratos/consumo y revisión humana definidos por contexto.

## 7. Riesgos y deudas documentadas

Proveedores/SDK y contrato exacto por ratificar; implementación y evidencia de Android pendientes. La maqueta no prueba Flutter.

## Aprobación y Control de Cambios

Estado: Borrador documental; sin implementación ni evidencia de producto.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: aplicación constitucional 0.3.0 sobre fuente Nexo 1.2.0; sin ratificación humana.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.1.0 | 2026-11-02 | Asistente, sin firma humana | Adaptación al patrón docente |

La tabla define cobertura de diseño, no pruebas ejecutadas. El plan concreta método/entorno; el checklist registra evidencia y revisión humana. Los escenarios compartidos no trasladan la propiedad del backend a Flutter.

## Revisión documental 0.3.0

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.3.0 | 2026-11-02 | Asistente, sin firma humana | Tareas reales, trazabilidad y criterio de propietario; sin aceptación de producto |

La traza acredita asignación documental, no pruebas ejecutadas. Las operaciones internas/admin y opcionales mantienen límites expresos.

## Integración y límites del desglose

Las historias de EP tienen un único dueño primario en el inventario y mapa bilateral; los requisitos agregados previos de fases origen verifican integración con sus subcapacidades. No son una segunda implementación. Una dependencia de cierre de experiencia integrada no impide construir el subset anterior que sí tiene contratos/entradas. Las condiciones bloqueantes específicas se resuelven antes de Ready de cada historia.

## Trazabilidad del incremento

| Requisito local | Tareas definidas | Criterios vinculados |
|---|---|---|
| FR-001 | T-001, T-002, T-010, T-003 | AC-001, AC-002, AC-090, AC-100 |
| NFR-001 | T-010, T-004 | AC-001, AC-002, AC-090, AC-100 |
| NFR-002 | T-001, T-007, T-005, T-501, T-505, T-526, T-403, T-404, T-406, T-411, T-418, T-451, T-452, T-453, T-454, T-455, T-456 | AC-001, AC-002, AC-090, AC-100, AC-403, AC-404, AC-406, AC-411, AC-418, AC-451, AC-452, AC-453, AC-454, AC-455, AC-456, AC-501, AC-505, AC-526 |
| NFR-003 | T-002, T-010, T-021, T-003, T-005, T-501, T-505, T-526, T-403, T-404, T-406, T-411, T-418, T-451, T-452, T-453, T-454, T-455, T-456 | AC-001, AC-002, AC-090, AC-100, AC-403, AC-404, AC-406, AC-411, AC-418, AC-451, AC-452, AC-453, AC-454, AC-455, AC-456, AC-501, AC-505, AC-526 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-090, AC-100 |
| FR-501 | T-501 | AC-501 |
| FR-505 | T-505 | AC-505 |
| FR-526 | T-526 | AC-526 |
| FR-403 | T-403 | AC-403 |
| FR-404 | T-404 | AC-404 |
| FR-406 | T-406 | AC-406 |
| FR-411 | T-411 | AC-411 |
| FR-418 | T-418 | AC-418 |
| FR-451 | T-451 | AC-451 |
| FR-452 | T-452 | AC-452 |
| FR-453 | T-453 | AC-453 |
| FR-454 | T-454 | AC-454 |
| FR-455 | T-455 | AC-455 |
| FR-456 | T-456 | AC-456 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
