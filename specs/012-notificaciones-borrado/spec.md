# 012-NOTIFICACIONES-BORRADO — Notificaciones y eliminación distribuida completa

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `012-notificaciones-borrado`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5/6; D05.

Notificaciones y eliminación distribuida completa. Servicios involucrados: S07, S01, S02, S03, S04, S05, S06.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Notificaciones y eliminación distribuida completa

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 07, 10, 15, 16. Componentes: M22, M24. Hallazgos: H01, H02, H03.

Dependencias: 004-identidad-sesion para inicio; 005..011 para cierre integrado; nv-12.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Integrar avisos/bandeja/dispositivos de 022 con logout/eliminación; implementación primaria de push en 022.
- FR-002: Cuenta solicita borrado y consulta progreso hasta confirmación de todos.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Push es aviso, bandeja durable deduplica; logout desvincula token de dispositivo.
- Evento mínimo; destino revalida permisos al abrir.
- Saga no declara completado al recibir solicitud. S08 confirma si está habilitado.

- FR-090: Diseñar permiso push, rutas autorizadas, bandeja sin push y eliminación con reautenticación, purga local y progreso hasta confirmación.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Push a sesión anterior no entrega datos de nueva cuenta; borrado parcial no informa completado; cuenta bloqueada de inmediato; restaurar backup aplica supresiones antes de servir.

- FR-100: Definir permiso push, asociación por sesión/dispositivo, destino reautorizado, bandeja sin permiso y progreso real de eliminación con purga local.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5/6; D05.

### Historias de consumo por intención

- FR-212: Consumir EP-012 para solicitar eliminación integral, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-213: Consumir EP-013 para consultar progreso del borrado, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-12/spec.md).

S07: devices/notifications/deliveries; S01 deletions y acuses de cada servicio habilitado. Dedupe por eventId/destinatario; tombstones impiden reaparición. Retención/backups requieren decisión explícita.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Sin permiso push se conserva bandeja.
- [ ] AC-002: Reentrega de evento no duplica notificación ni efecto de borrado.
- [ ] AC-003: Borrado parcial muestra pendiente; cuenta queda bloqueada; backups/retención documentados.

- [ ] AC-090 → FR-090/NFR-090: Push a sesión anterior no entrega datos de nueva cuenta; borrado parcial no informa completado; cuenta bloqueada de inmediato; restaurar backup aplica supresiones antes de servir.

- [ ] AC-100 → FR-100/NFR-100: Push de cuenta anterior no revela contenido; destino cancelado no abre domicilio; sin permiso existe bandeja; trámite parcial se mantiene pendiente y no puede reaparecer cola privada borrada.

- [ ] AC-212 → FR-212/NFR-001/NFR-003: EP-012: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Bloquear cuenta y emitir evento; no afirmar completado al recibir La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-213 → FR-213/NFR-001/NFR-003: EP-013: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Receipt solo permite consultar este trámite, nunca reabrir cuenta La UI refleja la regla del servidor, no la sustituye.

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
| NFR-001 | T-010, T-011, T-004, T-212, T-213 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-212, AC-213 |
| NFR-002 | T-001, T-007, T-005 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-212, T-213 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-212, AC-213 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-212 | T-212 | AC-212 |
| FR-213 | T-213 | AC-213 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
