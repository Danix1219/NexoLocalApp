# 021-INTERESADOS-CANDIDATOS — Interesados y candidatos

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `021-interesados-candidatos`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-20/spec.md).

## 2. Objetivo

Expresar/retirar interés, consultar interesados propios y pedir desde candidato.

## 3. Alcance / Fuera de alcance

Dependencias: 009-solicitudes/006-perfiles; integrar 010; nv-20. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Expresar/retirar interés, consultar interesados propios y pedir desde candidato.
- FR-002: Aplicar la regla: Shortlist opcional; filtro y modo no conceden permiso.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Otro usuario no accede a interesados; fuera de categoría visible no se bloquea arbitrariamente.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Historias de consumo por intención

- FR-253: Consumir EP-053 para expresar interés, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-254: Consumir EP-054 para retirar interés, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-255: Consumir EP-055 para consultar interesados y ordenar, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-256: Consumir EP-056 para [ampliación opcional] preseleccionar candidato, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Opcional; no bloquea alcance obligatorio si no se habilita.
- FR-257: Consumir EP-057 para [ampliación opcional] quitar preselección, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Opcional; no bloquea alcance obligatorio si no se habilita.

### Funcionalidades y obligaciones con dueño explícito

- FR-516: M16 Mis solicitudes e interesados: Actor Solicitante: Lista propia por autor, interesados ordenables y pedir servicio; preselección no visible, queda extensión opcional.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. Shortlist opcional; filtro y modo no conceden permiso.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Otro usuario no accede a interesados; fuera de categoría visible no se bloquea arbitrariamente.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: Shortlist opcional; filtro y modo no conceden permiso. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-253 → FR-253/NFR-001/NFR-003: EP-053: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solicitud abierta ajena y perfil activo; una relación única; no impedir por categoría no coincidente: la maqueta permite esa acción; mantener visibilidad y estado como restricciones. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-254 → FR-254/NFR-001/NFR-003: EP-054: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No alterar asignación existente; retirar relación propia La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-255 → FR-255/NFR-001/NFR-003: EP-055: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Enriquecer por lote con S02/S03 y mantener cursor estable La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-256 → FR-256/NFR-001/NFR-003: EP-056: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Requiere interés existente; no equivale a aceptación La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-257 → FR-257/NFR-001/NFR-003: EP-057: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo dueño; operación idempotente La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-516 → FR-516/NFR-002/NFR-003: Solo dueño consulta interesados y elige. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Otro usuario no accede a interesados; fuera de categoría visible no se bloquea arbitrariamente.

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
| NFR-001 | T-010, T-011, T-004, T-253, T-254, T-255, T-256, T-257 | AC-001, AC-002, AC-100, AC-253, AC-254, AC-255, AC-256, AC-257 |
| NFR-002 | T-001, T-007, T-005, T-516 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-516 |
| NFR-003 | T-002, T-012, T-003, T-005, T-253, T-254, T-255, T-256, T-257, T-516 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-253, AC-254, AC-255, AC-256, AC-257, AC-516 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-253 | T-253 | AC-253 |
| FR-254 | T-254 | AC-254 |
| FR-255 | T-255 | AC-255 |
| FR-256 | T-256 | AC-256 |
| FR-257 | T-257 | AC-257 |
| FR-516 | T-516 | AC-516 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
