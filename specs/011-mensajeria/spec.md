# 011-MENSAJERIA — Conversaciones, mensajes y avisos en vivo

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `011-mensajeria`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5/6; H05/H11.

Conversaciones, mensajes y avisos en vivo. Servicios involucrados: S05, S04, S06, S02.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Conversaciones, mensajes y avisos en vivo

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 07, 09, 15, 16. Componentes: M18, M19. Hallazgos: H05, H11.

Dependencias: 010-pedidos, 005-contenido-seguro y nv-11.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Participantes intercambian texto/foto y recuperan historial al reconectar.
- FR-002: Usuario filtra no leídos y bloquea/desbloquea.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- REST persiste y confirma; WS avisa; Redis Pub/Sub no conserva historial.
- Pareja orientada cliente/prestador por IDs; contexto de pedido/solicitud por mensaje.
- Respuesta rápida usa mismo SendMessage sin sobrescribir con textarea vacío.

- FR-090: Diseñar bandeja, texto/foto/respuesta rápida, pendiente/confirmado/fallo y recuperación por cursor al reconectar.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H05/H11: texto rápido/manual utiliza misma intención; reintento mismo ID da una entrega; nuevo pedido cambia cabecera sin reescribir mensajes; logout invalida conexión existente.

- FR-100: Definir envío manual/rápido/foto con estado pendiente/confirmado/fallo, contexto por mensaje y recuperación de secuencia tras reconexión y cambio de cuenta.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5/6; H05/H11.

### Historias de consumo por intención

- FR-266: Consumir EP-066 para abrir o recuperar conversación por pareja, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-267: Consumir EP-067 para listar bandeja y no leídos por modo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-268: Consumir EP-068 para recuperar historial o mensajes tras desconexión, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-269: Consumir EP-069 para enviar texto o foto aprobados, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-270: Consumir EP-070 para marcar lectura hasta secuencia, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-271: Consumir EP-071 para bloquear a contraparte, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-272: Consumir EP-072 para desbloquear contraparte, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-273: Consumir EP-073 para emitir ticket de conexión websocket, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-274: Consumir EP-074 para recibir avisos de mensajes y pedidos, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-518: M18 Bandeja de mensajes: Actor Participantes: Conversaciones, filtro no leídos, badge y estado vacío.
- FR-519: M19 Chat: Actor Miembros: Historial paginado, texto, foto, respuestas rápidas, avisos, pedido, menú y bloqueo.

- FR-705: Corregir H05: Respuesta rápida real; integrar propietarios implicados sin duplicar regla.

- FR-711: Corregir H11: Contexto de chat por mensaje; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-11/spec.md).

S05: conversations/messages/blocks; unique conversationId/clientMessageId, sequence durable y contexto requestId/orderId por mensaje; Redis Pub/Sub no historial. WS no lleva JWT en URL persistible.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Mensaje manual y rápido aparecen una vez con el mismo clientMessageId reintentado.
- [ ] AC-002: Bloqueo en cualquier dirección impide nuevos envíos autorizados; conservar historial permitido.
- [ ] AC-003: Nuevo pedido no cambia contexto histórico; cabecera distingue pedido activo.
- [ ] AC-004: Reconexión recupera secuencia faltante aunque se pierda un aviso WS.

- [ ] AC-090 → FR-090/NFR-090: H05/H11: texto rápido/manual utiliza misma intención; reintento mismo ID da una entrega; nuevo pedido cambia cabecera sin reescribir mensajes; logout invalida conexión existente.

- [ ] AC-100 → FR-100/NFR-100: Respuesta rápida no se sobrescribe por campo vacío; mismo ID produce una burbuja confirmada; nuevo pedido no altera mensajes anteriores; logout corta WS y evita reenvío de otra cuenta.

- [ ] AC-266 → FR-266/NFR-001/NFR-003: EP-066: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Prestador inicia solo tras asignación; comprobar bloques y membresía; consultar chatEnabled actual para nueva conversación; acceso por rol/contexto autorizado. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-267 → FR-267/NFR-001/NFR-003: EP-067: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No exponer conversaciones de otro modo/miembro La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-268 → FR-268/NFR-001/NFR-003: EP-068: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Autorización en cada página; adjuntos privados bajo control La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-269 → FR-269/NFR-001/NFR-003: EP-069: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Moderar antes de persistir; retry devuelve mismo mensaje; no respuesta simulada; texto 1..600; respuesta rápida y manual comparten SendMessage sin sobrescribir el texto seleccionado. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-270 → FR-270/NFR-001/NFR-003: EP-070: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Monótono; no avanzar más allá de mensaje disponible La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-271 → FR-271/NFR-001/NFR-003: EP-071: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Revalidar bloqueo al enviar; no solo silenciar UI La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-272 → FR-272/NFR-001/NFR-003: EP-072: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No retirar bloqueo impuesto por la otra persona La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-273 → FR-273/NFR-001/NFR-003: EP-073: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Guardar hash/TTL en Redis de seguridad; no JWT en URL duradera La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-274 → FR-274/NFR-001/NFR-003: EP-074: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Validar membresía, sesión y bloqueos durante conexión; reanudar por REST La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-518 → FR-518/NFR-002/NFR-003: No mezclar parejas por nombre ni modo. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-519 → FR-519/NFR-002/NFR-003: Confirmación duradera y recuperación tras desconexión. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-705 → FR-705/NFR-001/NFR-003: Respuesta rápida y manual usan la misma intención; texto elegido no se sobrescribe por campo vacío y reintento no duplica.

- [ ] AC-711 → FR-711/NFR-001/NFR-003: Nueva orden no reescribe contexto histórico; mensaje/evento tiene orderId/requestId autorizado y cabecera muestra pedido activo.

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
| NFR-001 | T-010, T-011, T-004, T-266, T-267, T-268, T-269, T-270, T-271, T-272, T-273, T-274, T-705, T-711 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-266, AC-267, AC-268, AC-269, AC-270, AC-271, AC-272, AC-273, AC-274, AC-705, AC-711 |
| NFR-002 | T-001, T-007, T-005, T-518, T-519 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-518, AC-519 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-266, T-267, T-268, T-269, T-270, T-271, T-272, T-273, T-274, T-518, T-519, T-705, T-711 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-266, AC-267, AC-268, AC-269, AC-270, AC-271, AC-272, AC-273, AC-274, AC-518, AC-519, AC-705, AC-711 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| FR-266 | T-266 | AC-266 |
| FR-267 | T-267 | AC-267 |
| FR-268 | T-268 | AC-268 |
| FR-269 | T-269 | AC-269 |
| FR-270 | T-270 | AC-270 |
| FR-271 | T-271 | AC-271 |
| FR-272 | T-272 | AC-272 |
| FR-273 | T-273 | AC-273 |
| FR-274 | T-274 | AC-274 |
| FR-518 | T-518 | AC-518 |
| FR-519 | T-519 | AC-519 |
| FR-705 | T-705 | AC-705 |
| FR-711 | T-711 | AC-711 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
