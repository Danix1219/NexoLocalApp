# 009-SOLICITUDES — Solicitudes, intereses y candidatos

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `009-solicitudes`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5; H12.

Solicitudes, intereses y candidatos. Servicios involucrados: S04, S02, S03.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Solicitudes, intereses y candidatos

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 07, 14, 16. Componentes: M09, M13, M16. Hallazgos: H12.

Dependencias: 006-perfiles, 005-contenido-seguro y nv-09.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cliente publica/edita/consulta solicitudes propias; interesados se integran desde 021.
- FR-002: Integrar interés/retiro/candidatos de 021 respetando visibilidad y estado vigente.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Solicitud 10..280, urgencia Hoy separada de fecha de creación y ownerOnly distinto de matchMyServices.
- Coincidencia de categoría es filtro; visibilidad/estado restringen interés.
- Preselección explícita es extensión opcional, sin bloquear el alcance visible.

- FR-090: Diseñar publicar/buscar solicitudes, expresar/retirar interés y consultar interesados propios; filtros de coincidencia y urgencia independientes.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H12: urgencia Hoy incluye publicación anterior; un prestador puede interesarse fuera de categoría coincidente si visibilidad/estado lo permiten; shortlist no bloquea aceptación.

- FR-100: Definir listas propias/interesados, filtros de coincidencia/urgencia y acciones por estado recibido sin convertir filtro o modo en autorización.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5; H12.

### Historias de consumo por intención

- FR-247: Consumir EP-047 para publicar necesidad de servicio, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-248: Consumir EP-048 para consultar solicitudes de zona y capacidad, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-249: Consumir EP-049 para abrir solicitud, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-250: Consumir EP-050 para corregir necesidad abierta, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-251: Consumir EP-051 para cerrar necesidad ya resuelta, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-252: Consumir EP-052 para retirar solicitud, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-509: M09 Buscar solicitudes: Actor Prestador: Filtro categoría, en zona, propias y recientes; tarjeta y detalle.
- FR-513: M13 Publicar necesidad: Actor Solicitante: Texto, categoría sugerida/manual, urgencia, zona y contacto.

- FR-712: Corregir H12: Límites y filtros reales; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-09/spec.md).

S04: requests/interests, único requestId/providerId; estado y propietario, urgencies=Hoy diferente de createdToday; no teléfono/domicilio en lectura pública.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Propia/cerrada no admite interés; duplicado es idempotente.
- [ ] AC-002: Urgencia Hoy devuelve urgentes aunque se hayan publicado ayer.
- [ ] AC-003: No devolver teléfono ni domicilio en lista/detalle público.

- [ ] AC-090 → FR-090/NFR-090: H12: urgencia Hoy incluye publicación anterior; un prestador puede interesarse fuera de categoría coincidente si visibilidad/estado lo permiten; shortlist no bloquea aceptación.

- [ ] AC-100 → FR-100/NFR-100: Hoy muestra urgencia aunque la publicación sea anterior; propia/cerrada no ofrece interés; otro usuario no abre interesados; shortlist no se añade a aceptación obligatoria.

- [ ] AC-247 → FR-247/NFR-001/NFR-003: EP-047: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Texto moderado mínimo diez caracteres; no mostrar teléfono público; máximo 280 caracteres; contactPreference chat/both. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-248 → FR-248/NFR-001/NFR-003: EP-048: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; ownerOnly requiere sesión; matchMyServices compara categorías del perfil sin confundir propiedad. urgency=Hoy filtra urgencia, no antigüedad. Respuesta fuera de cobertura etiquetada y por ampliación explícita. Nunca domicilio ni teléfono público. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-249 → FR-249/NFR-001/NFR-003: EP-049: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Propietario obtiene sus datos privados; otros solo zona La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-250 → FR-250/NFR-001/NFR-003: EP-050: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo abierta sin asignación; moderación de texto modificado; nunca ampliar acceso a teléfono de pedido fuera de la autorización del cliente. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-251 → FR-251/NFR-001/NFR-003: EP-051: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Si hay pedido ok, exigir resolver/cancelar antes para no contradecirlo La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-252 → FR-252/NFR-001/NFR-003: EP-052: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No borrar un pedido activo en cascada; ocultar y auditar La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-509 → FR-509/NFR-002/NFR-003: Datos públicos aproximados; solicitud cerrada no ofrece interés. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-513 → FR-513/NFR-002/NFR-003: No publicar sin moderación ni confirmación remota. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-712 → FR-712/NFR-001/NFR-003: Tres precios, seis fotos portafolio/cuatro por trabajo se conservan en sus dueños; urgencia Hoy no es fecha de creación y shortlist sigue opcional.

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
| NFR-001 | T-010, T-011, T-004, T-247, T-248, T-249, T-250, T-251, T-252, T-712 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-247, AC-248, AC-249, AC-250, AC-251, AC-252, AC-712 |
| NFR-002 | T-001, T-007, T-005, T-509, T-513 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-509, AC-513 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-247, T-248, T-249, T-250, T-251, T-252, T-509, T-513, T-712 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-247, AC-248, AC-249, AC-250, AC-251, AC-252, AC-509, AC-513, AC-712 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-247 | T-247 | AC-247 |
| FR-248 | T-248 | AC-248 |
| FR-249 | T-249 | AC-249 |
| FR-250 | T-250 | AC-250 |
| FR-251 | T-251 | AC-251 |
| FR-252 | T-252 | AC-252 |
| FR-509 | T-509 | AC-509 |
| FR-513 | T-513 | AC-513 |
| FR-712 | T-712 | AC-712 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
