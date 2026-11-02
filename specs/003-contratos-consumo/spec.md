# 003-CONTRATOS-CONSUMO — Contratos y consumo de API

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `003-contratos-consumo`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§3/4/5/6; D02.

Fase de fundamento previa a funcionalidad. Conserva el orden de aprendizaje del profesor sin copiar infraestructura incompatible.

## 2. Objetivo

Contratos y consumo de API

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: SDD, calidad, contratos y entrega; no reemplaza el alcance de funcionalidades.

Dependencias: 002-quality-gates; contrato de historia coordinado con nv-02.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Definir semántica del cliente HTTP: baseUrl por entorno, credenciales seguras, renovación coordinada, cancelación y política por error/reintento/versión.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Sin producto ni proveedor simulado presentado como real.
- Contratos/plantillas y configuración no deben contradecir la constitución.

- FR-090: Definir cliente remoto/local, contrato por operación consumida, errores y política de reintentos; HTTP de producto siempre por API.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Clasificar 401/403, conflicto 409, validación 422, límite 429 y dependencia caída; confirmar semántica exacta en contrato antes de generar consumidores.

- FR-100: Definir semántica del cliente HTTP: baseUrl por entorno, credenciales seguras, renovación coordinada, cancelación y política por error/reintento/versión.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§3/4/5/6; D02.

### Funcionalidades y obligaciones con dueño explícito

- FR-412: R12 MCP opcional: Atender el requisito académico 12 en su superficie y coordinar la contraparte.
- FR-413: R13 Nube y balanceo: Atender el requisito académico 13 en su superficie y coordinar la contraparte.
- FR-414: R14 NoSQL: Atender el requisito académico 14 en su superficie y coordinar la contraparte.
- FR-415: R15 Backend operativo: Atender el requisito académico 15 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md).

API: evidencia por suite y propietario. App: modelos desde contrato cuando se autoricen generadores, cursores/versiones y estado de sincronización; no DTO manual divergente.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Documentos y límites coherentes con la constitución; lint documental sin referencias rotas.
- [ ] AC-002: Cuando se implemente esta fase, comandos y rutas reales constan en plan y evidencia; sin verdes prestados del profesor.

- [ ] AC-090 → FR-090/NFR-090: Clasificar 401/403, conflicto 409, validación 422, límite 429 y dependencia caída; confirmar semántica exacta en contrato antes de generar consumidores.

- [ ] AC-100 → FR-100/NFR-100: 401 no crea bucle de refresh; 403 no reintenta como fallo de red; 409 requiere refrescar/resolver; 429 respeta Retry-After; timeout no duplica escritura y el mismo ID se conserva al reintentar.

- [ ] AC-412 → FR-412/NFR-002/NFR-003: Si se adopta, registrar origen, versión, finalidad y permisos mínimos; ausencia de MCP no bloquea producto ni autoriza instalaciones. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-413 → FR-413/NFR-002/NFR-003: Acreditar nube elegida, balanceo y TLS; crear/eliminar infraestructura con procedimiento seguro. Terraform es recomendación, no imposición automática. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-414 → FR-414/NFR-002/NFR-003: Justificar motor por función y bases por propietario; definir scripts idempotentes, llaves/índices/validadores, migración y restauración. SQLite es local. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-415 → FR-415/NFR-002/NFR-003: Verificar AWS/Azure/GCP y costo cero acordado, dos réplicas API, Redis/JWT, CDN, observabilidad, caching/rate-limit/middleware/paginación/índices/serialización/compresión y ciclo de infraestructura. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

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
| FR-001 | T-001, T-002, T-010, T-003 | AC-001, AC-002, AC-090, AC-100 |
| NFR-001 | T-010, T-004 | AC-001, AC-002, AC-090, AC-100 |
| NFR-002 | T-001, T-007, T-005, T-412, T-413, T-414, T-415 | AC-001, AC-002, AC-090, AC-100, AC-412, AC-413, AC-414, AC-415 |
| NFR-003 | T-002, T-010, T-021, T-003, T-005, T-412, T-413, T-414, T-415 | AC-001, AC-002, AC-090, AC-100, AC-412, AC-413, AC-414, AC-415 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-090, AC-100 |
| FR-412 | T-412 | AC-412 |
| FR-413 | T-413 | AC-413 |
| FR-414 | T-414 | AC-414 |
| FR-415 | T-415 | AC-415 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
