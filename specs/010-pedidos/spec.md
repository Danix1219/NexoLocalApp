# 010-PEDIDOS — Pedidos, privacidad de contacto y resolución

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `010-pedidos`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5/6; H01/H02.

Pedidos, privacidad de contacto y resolución. Servicios involucrados: S04, S02, S01, S03.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Pedidos, privacidad de contacto y resolución

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 07, 10, 14, 15, 16. Componentes: M17, M27. Hallazgos: H01, H02.

Dependencias: 009-solicitudes, 006-perfiles y nv-10; entrada chat se completa con 011-mensajeria.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cliente envía pedido desde perfil, candidato o chat.
- FR-002: Prestador acepta con precio opcional o rechaza; participantes cancelan; prestador resuelve.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- pend→ok/cancel; ok→done/cancel; done/cancel terminales.
- Aceptar y asignar solicitud son transacción local S04 con version/outbox.
- Teléfono cliente exige participante autorizado, estado ok/done y both vigente.
- Rechazo/cancelación revoca ubicación precisa y rutas; solo devuelve zona.

- FR-090: Diseñar envío, aceptar/rechazar/cancelar/resolver y cambio de domicilio; datos sensibles, copia y ruta dependen del permiso vigente recibido.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H01/H02: pendiente/rechazado no expone teléfono/domicilio; cancelar retira también caché/rutas; dos aceptaciones simultáneas dejan solo una asignación activa.

- FR-100: Definir estados visibles de pedido, precio informativo, cambio de domicilio permitido, consentimiento y retirada de copia/ruta al cancelar o perder permiso.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5/6; H01/H02.

### Historias de consumo por intención

- FR-258: Consumir EP-058 para enviar pedido desde perfil, chat o interesado, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-259: Consumir EP-059 para consultar pedidos por modo y estado, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-260: Consumir EP-060 para consultar estado y logística autorizada, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-261: Consumir EP-061 para aceptar y opcionalmente fijar precio, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-262: Consumir EP-062 para rechazar pedido pendiente, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-263: Consumir EP-063 para cancelar servicio activo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-264: Consumir EP-064 para declarar servicio resuelto, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-265: Consumir EP-065 para cambiar punto y referencias del servicio, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-517: M17 Pedido: Actor Participantes: Hoja de envío, dirección, pasos, aceptar/precio, rechazar/cancelar, resuelto y calificar.

- FR-702: Corregir H02: No revelar domicilio al rechazar/cancelar; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-10/spec.md).

S04: orders y referencia de asignación en requests; version, participante, precio informativo. pend→ok/cancel; ok→done/cancel. Rechazo se representa con cancel y razón ratificada; done/cancel terminales.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Dos aceptaciones simultáneas dejan una asignación activa; otra produce conflicto.
- [ ] AC-002: Pedido pendiente no entrega teléfono del cliente ni domicilio exacto.
- [ ] AC-003: Rechazar pendiente no expone dirección; cancelar aceptado retira permisos/cache.
- [ ] AC-004: Solo cliente dueño califica done; acción desde otro usuario se rechaza.

- [ ] AC-090 → FR-090/NFR-090: H01/H02: pendiente/rechazado no expone teléfono/domicilio; cancelar retira también caché/rutas; dos aceptaciones simultáneas dejan solo una asignación activa.

- [ ] AC-100 → FR-100/NFR-100: Pendiente/rechazado no muestra teléfono/dirección precisa; cancelar elimina información privada visible/local; conflicto refresca sin doble aceptación; no se aceptan/resuelven pedidos offline.

- [ ] AC-258 → FR-258/NFR-001/NFR-003: EP-058: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Idempotency-Key; impedir activos duplicados; verificar interés si origin=post; heredar de solicitud; directo chat por defecto y both solo por consentimiento explícito. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-259 → FR-259/NFR-001/NFR-003: EP-059: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Filtrar clientId o providerId derivado de sesión La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-260 → FR-260/NFR-001/NFR-003: EP-060: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Domicilio solo según estado y actor; no basta ocultarlo en Flutter La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-261 → FR-261/NFR-001/NFR-003: EP-061: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Transacción pedido+solicitud+outbox; solo pend; dirección después de commit La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-262 → FR-262/NFR-001/NFR-003: EP-062: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Liberar referencia de solicitud y retirar acceso privado La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-263 → FR-263/NFR-001/NFR-003: EP-063: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo pend/ok; invalidar autorización de domicilio y emitir evento La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-264 → FR-264/NFR-001/NFR-003: EP-064: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo ok; cerrar solicitud y habilitar calificación del cliente La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-265 → FR-265/NFR-001/NFR-003: EP-065: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo pend/ok; notificar cambio; no aceptar direcciones ajenas en evento público La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-517 → FR-517/NFR-002/NFR-003: Estados y dirección filtrados en servidor. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-702 → FR-702/NFR-001/NFR-003: Cancel/rechazo retira dirección precisa, caché y ruta; solo zona pública permanece.

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
| FR-001 | T-001, T-002, T-010, T-003 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| FR-002 | T-001, T-002, T-011, T-003 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| NFR-001 | T-010, T-011, T-004, T-258, T-259, T-260, T-261, T-262, T-263, T-264, T-265, T-702 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-258, AC-259, AC-260, AC-261, AC-262, AC-263, AC-264, AC-265, AC-702 |
| NFR-002 | T-001, T-007, T-005, T-517 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-517 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-258, T-259, T-260, T-261, T-262, T-263, T-264, T-265, T-517, T-702 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-258, AC-259, AC-260, AC-261, AC-262, AC-263, AC-264, AC-265, AC-517, AC-702 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| FR-258 | T-258 | AC-258 |
| FR-259 | T-259 | AC-259 |
| FR-260 | T-260 | AC-260 |
| FR-261 | T-261 | AC-261 |
| FR-262 | T-262 | AC-262 |
| FR-263 | T-263 | AC-263 |
| FR-264 | T-264 | AC-264 |
| FR-265 | T-265 | AC-265 |
| FR-517 | T-517 | AC-517 |
| FR-702 | T-702 | AC-702 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
