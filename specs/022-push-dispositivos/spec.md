# 022-PUSH-DISPOSITIVOS — Push, dispositivos y bandeja

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `022-push-dispositivos`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-21/spec.md).

## 2. Objetivo

Solicitar permiso en contexto, asociar por sesión y abrir avisos con revalidación.

## 3. Alcance / Fuera de alcance

Dependencias: 004-identidad-sesion y primer evento; nv-21. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Solicitar permiso en contexto, asociar por sesión y abrir avisos con revalidación.
- FR-002: Aplicar la regla: Push sin teléfono/domicilio/texto privado; bandeja disponible sin permiso.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Denegar push conserva bandeja; aviso antiguo no abre recurso revocado; logout desvincula token.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Historias de consumo por intención

- FR-283: Consumir EP-083 para registrar token push y preferencias, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-284: Consumir EP-084 para desvincular push del dispositivo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-285: Consumir EP-085 para consultar notificaciones persistentes, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-286: Consumir EP-086 para marcar aviso leído, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-522: M22 Notificaciones: Actor Cuenta: Bandeja, badge, abrir recurso y preferencias.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. Push sin teléfono/domicilio/texto privado; bandeja disponible sin permiso.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Denegar push conserva bandeja; aviso antiguo no abre recurso revocado; logout desvincula token.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: Push sin teléfono/domicilio/texto privado; bandeja disponible sin permiso. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-283 → FR-283/NFR-001/NFR-003: EP-083: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Asociado a sid actual; token único; rotación La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-284 → FR-284/NFR-001/NFR-003: EP-084: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Idempotente; no afectar otro usuario La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-285 → FR-285/NFR-001/NFR-003: EP-085: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Payload mínimo, acceso al destino se revalida al abrir La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-286 → FR-286/NFR-001/NFR-003: EP-086: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo aviso propio, idempotente La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-522 → FR-522/NFR-002/NFR-003: Acceso revalidado al seguir push. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Denegar push conserva bandeja; aviso antiguo no abre recurso revocado; logout desvincula token.

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
| NFR-001 | T-010, T-011, T-004, T-283, T-284, T-285, T-286 | AC-001, AC-002, AC-100, AC-283, AC-284, AC-285, AC-286 |
| NFR-002 | T-001, T-007, T-005, T-522 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-522 |
| NFR-003 | T-002, T-012, T-003, T-005, T-283, T-284, T-285, T-286, T-522 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-283, AC-284, AC-285, AC-286, AC-522 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-283 | T-283 | AC-283 |
| FR-284 | T-284 | AC-284 |
| FR-285 | T-285 | AC-285 |
| FR-286 | T-286 | AC-286 |
| FR-522 | T-522 | AC-522 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
