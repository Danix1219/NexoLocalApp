# 005-CONTENIDO-SEGURO — Moderación y medios antes de persistir

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `005-contenido-seguro`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§2/4/5/6; D04/D05.

Moderación y medios antes de persistir. Servicios involucrados: S06.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Moderación y medios antes de persistir

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 07, 15, 16. Componentes: M23, M26. Hallazgos: Sin hallazgo específico asociado.

Dependencias: 004-identidad-sesion y nv-05; permisos de foto/cámara solo al necesitarlos.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Usuario envía texto o imagen y conoce aprobación/rechazo antes de publicar.
- FR-002: La app envía reporte con motivo y muestra confirmación remota; administración de reportes pertenece a la superficie autorizada del backend.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Vincular aprobación a contenido exacto, usuario y propósito; cambios exigen nueva validación.
- Medio de chat privado no recibe URL pública permanente.
- No persistir contenido rechazado ni cuerpos privados en logs.

- FR-090: Diseñar captura/selección, carga acotada, rechazo y reintento; UI solo confirma publicación con respuesta remota; administración no se presupone pantalla móvil.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Contenido editado invalida aprobación; proveedor caído impide persistir; un usuario no reutiliza aprobación ajena; reporte aceptado confirma persistencia real.

- FR-100: Definir captura/selección y permisos cámara/foto, borrador local, progreso/rechazo/reintento y publicación solo con confirmación autorizada.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§2/4/5/6; D04/D05.

### Historias de consumo por intención

- FR-275: Consumir EP-075 para moderar y registrar imagen, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-276: Consumir EP-076 para resolver acceso autorizado a medio, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-277: Consumir EP-077 para retirar archivo autorizado, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-278: Consumir EP-078 para reportar perfil, trabajo, experiencia o chat, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-279: Consumir EP-079 para consultar estado de sus reportes, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-299: Consumir EP-099 para obtener motivos y política vigente de reporte, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-523: M23 Reportes y confianza: Actor Cuenta: Motivos, envío, confirmación y señales de origen.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-05/spec.md).

S06: media, reports y decisiones. Aprobación por hash/autor/propósito/política; no bytes rechazados en Blob, CDN, logs ni temporales. App: borrador privado local y eliminación al salir.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Moderación caída impide publicación nueva y permite lectura previa.
- [ ] AC-002: Hash/propósito ajeno no sirve como aprobación; MIME/tamaño inválidos se rechazan.
- [ ] AC-003: Reporte sin motivo no se guarda; moderador no modifica directamente base ajena.

- [ ] AC-090 → FR-090/NFR-090: Contenido editado invalida aprobación; proveedor caído impide persistir; un usuario no reutiliza aprobación ajena; reporte aceptado confirma persistencia real.

- [ ] AC-100 → FR-100/NFR-100: Rechazo o caída del proveedor deja borrador privado y no estado publicado; negar permiso permite alternativa apropiada; no acceso directo a Blob público previo a revisión ni pantalla administrativa inferida.

- [ ] AC-275 → FR-275/NFR-001/NFR-003: EP-075: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Sin almacenamiento persistente previo; máximo 3 MB; validar contenido real La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-276 → FR-276/NFR-001/NFR-003: EP-076: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Revalidar boundResource; no entregar URL privada a visitante La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-277 → FR-277/NFR-001/NFR-003: EP-077: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Comprobar referencias y purgar CDN; no borrar medio ajeno La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-278 → FR-278/NFR-001/NFR-003: EP-078: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Validar acceso al objetivo; no copiar conversación completa a logs La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-279 → FR-279/NFR-001/NFR-003: EP-079: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No exponer identidad del moderador ni datos de terceros innecesarios La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-299 → FR-299/NFR-001/NFR-003: EP-099: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Complemento de contrato: frontend y backend comparten catálogo versionado de motivos; no recopilar datos privados en etiquetas. La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-523 → FR-523/NFR-002/NFR-003: Persistencia real y distinción de datos declarados. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

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
| NFR-001 | T-010, T-011, T-004, T-275, T-276, T-277, T-278, T-279, T-299 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-275, AC-276, AC-277, AC-278, AC-279, AC-299 |
| NFR-002 | T-001, T-007, T-005, T-523 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-523 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-275, T-276, T-277, T-278, T-279, T-299, T-523 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-275, AC-276, AC-277, AC-278, AC-279, AC-299, AC-523 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-275 | T-275 | AC-275 |
| FR-276 | T-276 | AC-276 |
| FR-277 | T-277 | AC-277 |
| FR-278 | T-278 | AC-278 |
| FR-279 | T-279 | AC-279 |
| FR-299 | T-299 | AC-299 |
| FR-523 | T-523 | AC-523 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
