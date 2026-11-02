# 004-IDENTIDAD-SESION — Identidad, sesión y aislamiento de cuenta

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `004-identidad-sesion`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§2/3/4/6; D02/D05.

Identidad, sesión y aislamiento de cuenta. Servicios involucrados: S01.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Identidad, sesión y aislamiento de cuenta

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 01, 07, 10, 15, 16. Componentes: M02, M03, M24. Hallazgos: H03.

Dependencias: 003-contratos-consumo y nv-04 para integración real.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Visitante crea cuenta verificando control real de teléfono y consentimientos.
- FR-002: La app inicia, renueva y cierra sesión; comprueba con la API revocación remota en ambas réplicas.
- FR-003: Integrar recuperación/cuenta/sesiones desde 017 y borrado desde 012 con reautenticación; mantener identidad mínima acotada.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- No aceptar OTP demo ni conservar contraseña en claro.
- La API gobierna JWT/refresh/revocación; Flutter renueva coordinando solicitudes concurrentes, usa almacenamiento seguro y nunca accede a Redis.
- Borrado bloquea acceso de inmediato, pero no informa completado sin confirmaciones.

- FR-090: Implementar en diseño registro/login/renovación/logout: almacenamiento seguro, limpieza de cuenta y estado de cierre local/remoto; servidor valida OTP y sesión.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Logout offline limpia acceso local y muestra revocación remota pendiente; recuperar contraseña invalida sesiones según política ratificada; refresh concurrente no crea bucles.

- FR-100: Definir continuidad de sesión, reautenticación y logout online/offline con limpieza de credenciales, imágenes privadas, borradores, SQLite y cola de sincronización.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§2/3/4/6; D02/D05.

### Historias de consumo por intención

- FR-201: Consumir EP-001 para solicitar verificación o recuperación del teléfono, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-202: Consumir EP-002 para comprobar código y obtener prueba de control, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-203: Consumir EP-003 para crear cuenta única y consentimiento, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-204: Consumir EP-004 para iniciar sesión con teléfono y contraseña, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-205: Consumir EP-005 para renovar sesión sin login repetido, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-207: Consumir EP-007 para cerrar sesión actual en backend y dispositivos, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-208: Consumir EP-008 para recuperar cuenta, capacidades y preferencias, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-502: M02 Autenticación: Actor Todos: Campos de teléfono/contraseña, código, reenvío, recuperar, ver contraseña y errores.
- FR-503: M03 Registro solicitante: Actor Cuenta: Stepper, datos personales, consentimiento e intereses opcionales.
- FR-410: R10 Logout: Atender el requisito académico 10 en su superficie y coordinar la contraparte.

- FR-703: Corregir H03: Aislamiento entre cuentas; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-04/spec.md).

S01: accounts, otp_challenges, sessions y deletions; teléfono normalizado único, proofToken de un uso, refresh hash/familia, estado durable. App: nunca OTP/contraseña persistidos; no JWT eterno.

## 6. Criterios de aceptación verificables

- [ ] AC-001: OTP incorrecto, expirado, reutilizado y límite de intentos se rechazan.
- [ ] AC-002: Ana sale y Carlos entra: Carlos no obtiene caché, borradores, experiencias o sesión de Ana.
- [ ] AC-003: Logout en instancia A hace rechazar el token anterior en B; fallo Redis no autoriza por omisión.
- [ ] AC-004: Reenvío y recuperación no enumeran cuentas; refresh repetido detecta replay.

- [ ] AC-090 → FR-090/NFR-090: Logout offline limpia acceso local y muestra revocación remota pendiente; recuperar contraseña invalida sesiones según política ratificada; refresh concurrente no crea bucles.

- [ ] AC-100 → FR-100/NFR-100: Ana sale y Carlos entra sin subir cola/borrador anterior; renovación concurrente usa una sola operación; logout offline muestra cierre local y estado remoto pendiente, sin conservar JWT de acceso general para cerrar después.

- [ ] AC-201 → FR-201/NFR-001/NFR-003: EP-001: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Respuesta neutral; límites por IP/teléfono; no devolver código La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-202 → FR-202/NFR-001/NFR-003: EP-002: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Verificar intentos, propósito, expiración y no reutilización La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-203 → FR-203/NFR-001/NFR-003: EP-003: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Teléfono único; nombre moderado; secreto protegido La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-204 → FR-204/NFR-001/NFR-003: EP-004: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Error neutral; hash adaptativo; nunca aceptar cuentas demo en release La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-205 → FR-205/NFR-001/NFR-003: EP-005: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Rotación atómica; replay revoca familia; coordinación de peticiones móviles La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-207 → FR-207/NFR-001/NFR-003: EP-007: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Revocación durable y Redis; cierre WebSocket; operación idempotente La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-208 → FR-208/NFR-001/NFR-003: EP-008: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; El modo de UI no concede privilegios La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-502 → FR-502/NFR-002/NFR-003: Recuperación real y mensajes sin enumeración de cuentas. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-503 → FR-503/NFR-002/NFR-003: Obligatorios validados, opcionales omitibles. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-410 → FR-410/NFR-002/NFR-003: Revocar en backend y limpiar móvil; rechazo entre dos réplicas y WS; offline solo acredita cierre local mientras remoto siga pendiente. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

- [ ] AC-703 → FR-703/NFR-001/NFR-003: Ana publica/guarda y sale; Carlos no recibe como propia autoría, borrador, cola o caché de Ana; IDs del token, nunca Tú/me.

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
| FR-003 | T-001, T-002, T-012, T-003 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| NFR-001 | T-010, T-011, T-012, T-004, T-201, T-202, T-203, T-204, T-205, T-207, T-208, T-703 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-201, AC-202, AC-203, AC-204, AC-205, AC-207, AC-208, AC-703 |
| NFR-002 | T-001, T-007, T-005, T-502, T-503, T-410 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-410, AC-502, AC-503 |
| NFR-003 | T-002, T-010, T-011, T-012, T-021, T-003, T-005, T-201, T-202, T-203, T-204, T-205, T-207, T-208, T-502, T-503, T-410, T-703 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-201, AC-202, AC-203, AC-204, AC-205, AC-207, AC-208, AC-410, AC-502, AC-503, AC-703 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| FR-201 | T-201 | AC-201 |
| FR-202 | T-202 | AC-202 |
| FR-203 | T-203 | AC-203 |
| FR-204 | T-204 | AC-204 |
| FR-205 | T-205 | AC-205 |
| FR-207 | T-207 | AC-207 |
| FR-208 | T-208 | AC-208 |
| FR-502 | T-502 | AC-502 |
| FR-503 | T-503 | AC-503 |
| FR-410 | T-410 | AC-410 |
| FR-703 | T-703 | AC-703 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
