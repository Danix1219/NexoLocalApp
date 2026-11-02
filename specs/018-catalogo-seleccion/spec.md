# 018-CATALOGO-SELECCION — Catálogo y selección

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `018-catalogo-seleccion`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-17/spec.md).

## 2. Objetivo

Consumir categorías activas en alta, filtros y publicación con caché versionada.

## 3. Alcance / Fuera de alcance

Dependencias: 003-contratos-consumo; nv-17; integrar 006/007/009. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Consumir categorías activas en alta, filtros y publicación con caché versionada.
- FR-002: Aplicar la regla: No invocar PUT admin; categoría obsoleta exige refresco sin perder borrador.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Catálogo caído permite lectura marcada; categoría retirada no se envía como válida.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Historias de consumo por intención

- FR-214: Consumir EP-014 para listar categorías, especialidades y sectores, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. No invocar PUT admin; categoría obsoleta exige refresco sin perder borrador.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Catálogo caído permite lectura marcada; categoría retirada no se envía como válida.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: No invocar PUT admin; categoría obsoleta exige refresco sin perder borrador. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-214 → FR-214/NFR-001/NFR-003: EP-014: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Excluir altas inactivas; caché público 24 h La UI refleja la regla del servidor, no la sustituye.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Catálogo caído permite lectura marcada; categoría retirada no se envía como válida.

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
| NFR-001 | T-010, T-011, T-004, T-214 | AC-001, AC-002, AC-100, AC-214 |
| NFR-002 | T-001, T-007, T-005 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-003 | T-002, T-012, T-003, T-005, T-214 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-214 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-214 | T-214 | AC-214 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
