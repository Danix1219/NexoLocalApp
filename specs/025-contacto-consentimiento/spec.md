# 025-CONTACTO-CONSENTIMIENTO — Contacto y consentimiento

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `025-contacto-consentimiento`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-25/spec.md).

## 2. Objetivo

Mostrar preferencias y permiso por pedido; retirar datos/copia/ruta al revocar.

## 3. Alcance / Fuera de alcance

Dependencias: 006/010; chat integra 011; nv-25. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Mostrar preferencias y permiso por pedido; retirar datos/copia/ruta al revocar.
- FR-002: Aplicar la regla: Dato recibido autorizado; no teléfono en caché pública; wa legacy significa chat interno.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Revocar showPhone/both retira dato; pendiente/cancelado no muestra contacto; fallo de política no concede permiso.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Historias de consumo por intención

- FR-291: Consumir EP-091 para obtener número del prestador para copiar, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-292: Consumir EP-092 para obtener contacto privado de la contraparte, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-296: Consumir EP-096 para configurar chat y visibilidad del número, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-297: Consumir EP-097 para dar o retirar permiso para compartir su teléfono, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Complemento de diseño; condición/UX y alcance se ratifican antes de Ready, sin pantalla inventada.

- FR-701: Corregir H01: No revelar teléfono de cliente pendiente; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. Dato recibido autorizado; no teléfono en caché pública; wa legacy significa chat interno.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Revocar showPhone/both retira dato; pendiente/cancelado no muestra contacto; fallo de política no concede permiso.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: Dato recibido autorizado; no teléfono en caché pública; wa legacy significa chat interno. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-291 → FR-291/NFR-001/NFR-003: EP-091: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Respuesta privada sin caché compartida; número validado por identidad; no mezclar en DTO público cacheable; exigir showPhone=true vigente; no confiar solo en canal visible en Flutter. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-292 → FR-292/NFR-001/NFR-003: EP-092: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Cliente: teléfono del prestador solo con showPhone vigente. Prestador: teléfono del cliente solo asignado en ok/done y clientContactPreference=both vigente. Cancelado o revocado: 403/404. No caché de contacto; comprobación autoritativa. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-296 → FR-296/NFR-001/NFR-003: EP-096: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; showPhone=false revoca lectura de teléfono inmediatamente. chatEnabled=false impide nuevas conversaciones; propuesta: historial y pedidos activos conservan chat. S05 consulta regla vigente. Alias local wa significa chat interno, no WhatsApp. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-297 → FR-297/NFR-001/NFR-003: EP-097: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Ampliación de privacidad: en pend/ok/done permite revocar; cancel no admite conceder. Cambiar a both no revela teléfono antes de ok. S04 es autoridad y retira cachés de contacto. La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-701 → FR-701/NFR-001/NFR-003: Participante prestador obtiene teléfono cliente solo en ok/done y both vigente; dato no existe en DTO ni copia no autorizados.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Revocar showPhone/both retira dato; pendiente/cancelado no muestra contacto; fallo de política no concede permiso.

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
| NFR-001 | T-010, T-011, T-004, T-291, T-292, T-296, T-297, T-701 | AC-001, AC-002, AC-100, AC-291, AC-292, AC-296, AC-297, AC-701 |
| NFR-002 | T-001, T-007, T-005 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-003 | T-002, T-012, T-003, T-005, T-291, T-292, T-296, T-297, T-701 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-291, AC-292, AC-296, AC-297, AC-701 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-291 | T-291 | AC-291 |
| FR-292 | T-292 | AC-292 |
| FR-296 | T-296 | AC-296 |
| FR-297 | T-297 | AC-297 |
| FR-701 | T-701 | AC-701 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
