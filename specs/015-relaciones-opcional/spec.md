# 015-RELACIONES-OPCIONAL — Proyección de relaciones y lectura del grafo

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `015-relaciones-opcional`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§2/4/5/6; D01/D03.

Proyección de relaciones y lectura del grafo. Servicios involucrados: S08, S02, S03, S01.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Proyección de relaciones y lectura del grafo

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 07, 14, 15. Componentes: Extensión opcional. Hallazgos: H03.

Dependencias: 008-comunidad, 012-notificaciones-borrado; nv-15 habilitado, si no N/A motivado.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Usuario obtiene candidatos relacionados con razón explicable.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Extensión condicionada a consultas/costo; CRUD actual continúa sin ella.
- Snapshots y eventId/sourceVersion evitan duplicados/replays; no PII ni permisos en grafo.

- FR-090: Diseñar sección opcional de relacionados explicables y degradación sin bloquear directorio ni pedidos.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Grafo caído no bloquea funciones obligatorias; replay antiguo no revive autor borrado; cambiar destinatario elimina relación anterior; consulta excedida se rechaza.

- FR-100: Definir visualización opcional de relacionados con explicación, paginación y degradación segura cuando S08 no está habilitado o falla.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§2/4/5/6; D01/D03.

### Historias de consumo por intención

- FR-298: Consumir EP-098 para consultar contexto y candidatos relacionados del grafo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Opcional; no bloquea alcance obligatorio si no se habilita.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-15/spec.md).

Neo4j derivado, nunca autoridad de permisos/PII. eventId/sourceVersion/snapshot y tombstones; retiro de aristas al editar/borrar. Operaciones GraphQL registradas, profundidad/costo/paginación acotados.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Grafo caído conserva directorio y pedidos.
- [ ] AC-002: Editar destinatario retira relación anterior; borrar autor elimina proyección.
- [ ] AC-003: Operación GraphQL excedida/no registrada se rechaza; paginación ligada a snapshot.

- [ ] AC-090 → FR-090/NFR-090: Grafo caído no bloquea funciones obligatorias; replay antiguo no revive autor borrado; cambiar destinatario elimina relación anterior; consulta excedida se rechaza.

- [ ] AC-100 → FR-100/NFR-100: Sin S08 se conservan búsqueda/pedidos; la app no construye relaciones privadas ni consulta Neo4j; dato fuera de permiso no se muestra y navegación vuelve a revalidar con propietario.

- [ ] AC-298 → FR-298/NFR-001/NFR-003: EP-098: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Extensión opcional de lectura, sin mutations ni Cypher arbitrario. Authorization por recurso/campo, dos saltos y profundidad propuesta 4; máximo 100 objetos, una operación y timeout 2 s. Coste y rate limit por usuario. No caché compartida de datos personalizados. La UI refleja la regla del servidor, no la sustituye.

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
| NFR-001 | T-010, T-004, T-298 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-298 |
| NFR-002 | T-001, T-007, T-005 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-003 | T-002, T-010, T-021, T-003, T-005, T-298 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-298 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-298 | T-298 | AC-298 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
