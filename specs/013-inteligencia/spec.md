# 013-INTELIGENCIA — ML y asistencia generativa evaluables

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `013-inteligencia`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§2/3/4/5/6/11; D06.

ML y asistencia generativa evaluables. Servicios involucrados: S06, Flutter.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

ML y asistencia generativa evaluables

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 07, 16. Componentes: M25. Hallazgos: Sin hallazgo específico asociado.

Dependencias: 005-contenido-seguro, 008-comunidad, 009-solicitudes y nv-13.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Usuario obtiene sugerencia ML de categoría desde imagen.
- FR-002: Usuario pide borrador generativo, lo edita y publica solo tras moderación.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Heurística de palabras no acredita ML; separar modelos/evaluación.
- No inventar garantías, licencias, precios o experiencia; abstenerse con baja confianza.

- FR-090: Definir función ML desde imagen y borrador GenAI editable; mostrar incertidumbre, permitir corrección y preservar edición manual.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Evaluar macro-F1/abstención/latencia según función acordada y generación sin inventar credenciales/precios; sin proveedor no aprobar integración académica aunque edición manual funcione.

- FR-100: Definir ML local de categorías y borrador generativo remoto como dos funciones distintas, con evaluación reproducible, abstención y edición manual.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§2/3/4/5/6/11; D06.

### Historias de consumo por intención

- FR-282: Consumir EP-082 para generar borrador editable de solicitud o trabajo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-525: M25 Asistencia inteligente: Actor Publicación: Sugerencia ML desde foto y borrador generado editable.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-13/spec.md).

Modelo/dataset separados de datos productivos, procedencia/consentimiento, conjunto evaluación independiente. GenAI no recibe contacto/domicilio/conversaciones privadas. Métricas y umbrales se fijan antes del ensayo.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Dataset separado entrenamiento/evaluación con procedencia y consentimiento.
- [ ] AC-002: Modelo sin confianza se abstiene; usuario corrige categoría.
- [ ] AC-003: API generativa caída no publica; salida no aprobada no se guarda.

- [ ] AC-090 → FR-090/NFR-090: Evaluar macro-F1/abstención/latencia según función acordada y generación sin inventar credenciales/precios; sin proveedor no aprobar integración académica aunque edición manual funcione.

- [ ] AC-100 → FR-100/NFR-100: Dataset prueba separado y autorizado; app muestra corrección/abstención y mide latencia en dispositivo; salida generativa no inventa precio/licencia ni publica; modelo caído no se presenta como éxito.

- [ ] AC-282 → FR-282/NFR-001/NFR-003: EP-082: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No persistir texto por defecto; sin datos precisos; moderar salida La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-525 → FR-525/NFR-002/NFR-003: Dos funciones reales, con abstención y sin publicación automática. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

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
| FR-001 | T-001, T-002, T-010, T-003 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-002 | T-001, T-002, T-011, T-003 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-001 | T-010, T-011, T-004, T-282 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-282 |
| NFR-002 | T-001, T-007, T-005, T-525 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-525 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-282, T-525 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-282, AC-525 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-282 | T-282 | AC-282 |
| FR-525 | T-525 | AC-525 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
