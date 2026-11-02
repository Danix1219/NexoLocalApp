# 020-EXPERIENCIAS-REPUTACION — Experiencias y reputación

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `020-experiencias-reputacion`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-19/spec.md).

## 2. Objetivo

Experiencia declarada/vinculada, estrellas, mención reactiva, edición y retiro.

## 3. Alcance / Fuera de alcance

Dependencias: 004/005/006; vinculada espera 010; nv-19. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Experiencia declarada/vinculada, estrellas, mención reactiva, edición y retiro.
- FR-002: Aplicar la regla: Una mención; registeredOrder ligado a pedido; EP-095 no supone nueva pantalla confirmada.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Quitar mención actualiza diálogo/formulario; sin elegibilidad no muestra pedido registrado; retirar refresca resumen.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Historias de consumo por intención

- FR-241: Consumir EP-041 para publicar experiencia o calificación, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-242: Consumir EP-042 para consultar opiniones y resumen, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-243: Consumir EP-043 para corregir experiencia, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-244: Consumir EP-044 para retirar experiencia, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-293: Consumir EP-093 para buscar prestador para mencionar en una experiencia, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-294: Consumir EP-094 para listar experiencias propias, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-295: Consumir EP-095 para abrir experiencia individual y su prestador, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Complemento de diseño; condición/UX y alcance se ratifican antes de Ready, sin pantalla inventada.

### Funcionalidades y obligaciones con dueño explícito

- FR-515: M15 Experiencia y estrellas: Actor Cuenta: Selector de prestador, texto, recomendación, estrellas y contexto de pedido.

- FR-704: Corregir H04: Mención reactiva; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. Una mención; registeredOrder ligado a pedido; EP-095 no supone nueva pantalla confirmada.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Quitar mención actualiza diálogo/formulario; sin elegibilidad no muestra pedido registrado; retirar refresca resumen.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: Una mención; registeredOrder ligado a pedido; EP-095 no supone nueva pantalla confirmada. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-241 → FR-241/NFR-001/NFR-003: EP-041: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Pedido done propio para registeredOrder; no autoevaluación; verificar prestador activo, un solo destinatario y campos obligatorios también en servidor; outbox review.upserted con versión. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-242 → FR-242/NFR-001/NFR-003: EP-042: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Distinguir declarado de pedido registrado; no inflar contadores La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-243 → FR-243/NFR-001/NFR-003: EP-043: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Moderar de nuevo y recalcular agregados; no cambiar autor/pedido; en registeredOrder providerId queda ligado al pedido; snapshot reemplaza relaciones de mención/recomendación anteriores. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-244 → FR-244/NFR-001/NFR-003: EP-044: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Actualizar promedio y recomendaciones; auditar retiro administrativo La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-293 → FR-293/NFR-001/NFR-003: EP-093: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Excluir perfil propio/inactivo; sin q sugerir cobertura cercana; con q buscar nombre/oficio sin imponer cercanía, como mresHTML. Sin teléfono ni coordenadas privadas. Búsqueda infija debe preservar resultados mediante índice/adaptador medido; no sustituirla silenciosamente por solo prefijo. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-294 → FR-294/NFR-001/NFR-003: EP-094: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Filtrar authorId del JWT; incluir prestador y estado visible al autor; sin depender del nombre Tú.; caso de aceptación obligatorio: Ana publica, logout, Carlos entra y no la obtiene como propia. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-295 → FR-295/NFR-001/NFR-003: EP-095: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Complemento de navegación: necesario para enlace estable/notificación propuesta, no pantalla individual confirmada en maqueta. La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-515 → FR-515/NFR-002/NFR-003: Separar experiencia declarada de pedido registrado. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-704 → FR-704/NFR-001/NFR-003: Quitar/cambiar prestador actualiza relación estructurada, chip y diálogo; registeredOrder no cambia destinatario fuera del pedido.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Quitar mención actualiza diálogo/formulario; sin elegibilidad no muestra pedido registrado; retirar refresca resumen.

## Aprobación y Control de Cambios

Estado: Borrador documental; sin implementación ni evidencia de producto.
Revisores: por asignar. Fecha: pendiente.

La traza acredita asignación documental, no pruebas ejecutadas. Las operaciones internas/admin y opcionales mantienen límites expresos.

## Integración y límites del desglose

Las historias de EP tienen un único dueño primario en el inventario y mapa bilateral; los requisitos agregados previos de fases origen verifican integración con sus subcapacidades. No son una segunda implementación. Una dependencia de cierre de experiencia integrada no impide construir el subset anterior que sí tiene contratos/entradas. Las condiciones bloqueantes específicas se resuelven antes de Ready de cada historia.

## Trazabilidad del incremento

| Requisito local | Tareas definidas | Criterios vinculados |
|---|---|---|
| FR-001 | T-001, T-002, T-010 | AC-001, AC-002, AC-003, AC-090 |
| FR-002 | T-001, T-002, T-011 | AC-001, AC-002, AC-003, AC-090 |
| FR-003 | T-001, T-002, T-012 | AC-001, AC-002, AC-003, AC-090 |
| FR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-001 | T-010, T-011, T-004, T-241, T-242, T-243, T-244, T-293, T-294, T-295, T-704 | AC-001, AC-002, AC-100, AC-241, AC-242, AC-243, AC-244, AC-293, AC-294, AC-295, AC-704 |
| NFR-002 | T-001, T-007, T-005, T-515 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-515 |
| NFR-003 | T-002, T-012, T-003, T-005, T-241, T-242, T-243, T-244, T-293, T-294, T-295, T-515, T-704 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-241, AC-242, AC-243, AC-244, AC-293, AC-294, AC-295, AC-515, AC-704 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-241 | T-241 | AC-241 |
| FR-242 | T-242 | AC-242 |
| FR-243 | T-243 | AC-243 |
| FR-244 | T-244 | AC-244 |
| FR-293 | T-293 | AC-293 |
| FR-294 | T-294 | AC-294 |
| FR-295 | T-295 | AC-295 |
| FR-515 | T-515 | AC-515 |
| FR-704 | T-704 | AC-704 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
