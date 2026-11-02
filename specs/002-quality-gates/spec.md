# 002-QUALITY-GATES — Gates de calidad y seguridad

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `002-quality-gates`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§6/7/8/11; D02.

Fase de fundamento previa a funcionalidad. Conserva el orden de aprendizaje del profesor sin copiar infraestructura incompatible.

## 2. Objetivo

Gates de calidad y seguridad

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: SDD, calidad, contratos y entrega; no reemplaza el alcance de funcionalidades.

Dependencias: 001-base-flutter.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Definir gates móviles unit/widget/integration/seguridad/analyze y expediente reproducible por requisito, incluyendo permisos, almacenamiento y accesibilidad.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Sin producto ni proveedor simulado presentado como real.
- Contratos/plantillas y configuración no deben contradecir la constitución.

- FR-090: Definir calidad desde el primer recorrido: unit/widget/integration, seguridad móvil y evidencia por requisito, con herramientas por ratificar.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Un consumidor puede reconocer nulos/enums/errores sin adivinar; una prueba con doble no se registra como integración real.

- FR-100: Definir gates móviles unit/widget/integration/seguridad/analyze y expediente reproducible por requisito, incluyendo permisos, almacenamiento y accesibilidad.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§6/7/8/11; D02.

### Funcionalidades y obligaciones con dueño explícito

- FR-402: R02 Evaluación interactiva y con prompts: Atender el requisito académico 2 en su superficie y coordinar la contraparte.
- FR-405: R05 SDD y DevSecOps: Atender el requisito académico 5 en su superficie y coordinar la contraparte.
- FR-407: R07 Pruebas: Atender el requisito académico 7 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md).

API: inventario EP, contrato formal futuro y envelope de eventos. App: fixtures sintéticos sin credenciales; evidencia distingue dobles, servidor y dispositivo.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Documentos y límites coherentes con la constitución; lint documental sin referencias rotas.
- [ ] AC-002: Cuando se implemente esta fase, comandos y rutas reales constan en plan y evidencia; sin verdes prestados del profesor.

- [ ] AC-090 → FR-090/NFR-090: Un consumidor puede reconocer nulos/enums/errores sin adivinar; una prueba con doble no se registra como integración real.

- [ ] AC-100 → FR-100/NFR-100: Cada gate distingue host, emulador y dispositivo, doble y API real; herramientas/versiones/rutas se fijan con proyecto, sin trasladar Stryker C# o umbral de una skill automáticamente.

- [ ] AC-402 → FR-402/NFR-002/NFR-003: Reconstruir requisito/spec/tarea/contrato/prueba/evidencia y recorrido interactivo sin respuestas inventadas. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-405 → FR-405/NFR-002/NFR-003: Aplicar constitución/spec/plan/tareas/checklist y controles de calidad desde cada incremento en ambos contextos. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-407 → FR-407/NFR-002/NFR-003: Preparar y ejecutar unitarias, seguridad e integración de ambas partes; distinguir dobles de MongoDB/Redis/proveedor/Android reales. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

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
| NFR-002 | T-001, T-007, T-005, T-402, T-405, T-407 | AC-001, AC-002, AC-090, AC-100, AC-402, AC-405, AC-407 |
| NFR-003 | T-002, T-010, T-021, T-003, T-005, T-402, T-405, T-407 | AC-001, AC-002, AC-090, AC-100, AC-402, AC-405, AC-407 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-090, AC-100 |
| FR-402 | T-402 | AC-402 |
| FR-405 | T-405 | AC-405 |
| FR-407 | T-407 | AC-407 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
