# 008-COMUNIDAD — Trabajos, experiencias, menciones y guardados

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `008-comunidad`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5/6; H03/H04/H07.

Trabajos, experiencias, menciones y guardados. Servicios involucrados: S03, S02, S06.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Trabajos, experiencias, menciones y guardados

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 07, 09, 14, 16. Componentes: M14, M15, M16, M20. Hallazgos: H03, H04, H07.

Dependencias: 006-perfiles, 005-contenido-seguro; vinculación espera 010-pedidos y nv-08.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Prestador publica trabajo/fotos; recomendaciones/guardados se integran desde 019.
- FR-002: Integrar experiencia declarada/vinculada, mención y reputación de 020 sin otro formulario/caso de uso divergente.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Trabajo 10..200 con hasta cuatro fotos; experiencia 10..280 con estrellas 1..5.
- Una mención estructurada providerId y authorId real; no identidad por displayName.
- Opinión de pedido requiere done y dueño validado en S04.

- FR-090: Diseñar publicación, quitar mención reactiva, guardados y borradores por cuenta; una opinión vinculada espera pedido elegible.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H03/H04/H07: cambio de cuenta no mezcla autoría; quitar mención actualiza diálogo; duplicar reintento de guardado no aumenta contador; fotos y pedidos se cuentan separados.

- FR-100: Definir borradores, selección/quitar mención reactiva, experiencia declarada/vinculada y guardados por cuenta, incluyendo conflicto al sincronizar.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5/6; H03/H04/H07.

### Historias de consumo por intención

- FR-231: Consumir EP-031 para publicar un trabajo realizado, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-232: Consumir EP-032 para consultar trabajos filtrados y perfil, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-233: Consumir EP-033 para abrir detalle de trabajo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-234: Consumir EP-034 para corregir contenido de trabajo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-235: Consumir EP-035 para retirar trabajo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-514: M14 Publicar trabajo: Actor Prestador: Texto 10..200, título automático, categoría, zona y hasta cuatro fotos; problema/tiempo residuales.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-08/spec.md).

S03: posts, reviews, reactions, saved y metrics. authorId del token; providerId estructurado; único por pedido cuando vinculado. Trabajo 10..200/cuatro fotos; experiencia 10..280/estrellas 1..5.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Quitar mención actualiza formulario y diálogo; sin prestador no publica.
- [ ] AC-002: Ana publica: Carlos no la ve como propia.
- [ ] AC-003: Repetir guardado/reacción no duplica ni aumenta contador indebidamente.

- [ ] AC-090 → FR-090/NFR-090: H03/H04/H07: cambio de cuenta no mezcla autoría; quitar mención actualiza diálogo; duplicar reintento de guardado no aumenta contador; fotos y pedidos se cuentan separados.

- [ ] AC-100 → FR-100/NFR-100: Quitar prestador actualiza chip/diálogo y exige selección para publicar; guardado repetido no duplica; opinión vinculada espera done; publicar offline nunca simula acuse; migración/cola local se especifica en 016.

- [ ] AC-231 → FR-231/NFR-001/NFR-003: EP-031: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Categoría ofrecida, 0..4 medios propios aprobados; título automático hasta 60 caracteres. No exigir campos residuales problema/tiempo. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-232 → FR-232/NFR-001/NFR-003: EP-032: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo publicados; orden por createdAt y _id La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-233 → FR-233/NFR-001/NFR-003: EP-033: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No exponer domicilio donde se realizó La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-234 → FR-234/NFR-001/NFR-003: EP-034: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Volver a moderar cambios; conservar versión anterior solo según política La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-235 → FR-235/NFR-001/NFR-003: EP-035: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Ocultar feed e invalidar caché; purgar medios que queden sin referencias La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-514 → FR-514/NFR-002/NFR-003: Galería aprobada y borrador recuperable. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

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

La [spec 016 de sincronización local](../016-sincronizacion-local/spec.md) es autoridad del comportamiento transversal de cola/migraciones/conflictos; este recorrido conserva sus reglas de negocio y contratos, sin duplicar su implementación.

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
| NFR-001 | T-010, T-011, T-004, T-231, T-232, T-233, T-234, T-235 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-231, AC-232, AC-233, AC-234, AC-235 |
| NFR-002 | T-001, T-007, T-005, T-514 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-514 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-231, T-232, T-233, T-234, T-235, T-514 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-231, AC-232, AC-233, AC-234, AC-235, AC-514 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-231 | T-231 | AC-231 |
| FR-232 | T-232 | AC-232 |
| FR-233 | T-233 | AC-233 |
| FR-234 | T-234 | AC-234 |
| FR-235 | T-235 | AC-235 |
| FR-514 | T-514 | AC-514 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
