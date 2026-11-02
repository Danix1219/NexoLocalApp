# 007-DESCUBRIMIENTO — Búsqueda, mapa, comparación y feed público

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `007-descubrimiento`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5/6; H08/H10.

Búsqueda, mapa, comparación y feed público. Servicios involucrados: S02, S03, G01.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Búsqueda, mapa, comparación y feed público

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 09, 15, 16. Componentes: M01, M06, M07, M08, M10, M12. Hallazgos: H08.

Dependencias: 006-perfiles; feed ampliado se integra con 008-comunidad y nv-07.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Visitante busca por zona y categoría; registro al intentar acciones protegidas.
- FR-002: Cuenta compara dos prestadores con condiciones comparables.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Paginación estable, cobertura por modalidad y ampliación fuera de radio explícita.
- No etiquetar mejor precio cuando servicio/unidad/moneda/materiales no coinciden.

- FR-090: Diseñar visitante, búsqueda/mapa, comparación máxima de dos, estados vacíos y caché pública con antigüedad visible; acciones protegidas retoman tras registro.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H08/H10: comparar solo serviceKey/unidad/moneda/materiales; local con radio cero aparece; denegar GPS conserva entrada manual; edición invalida caché entre réplicas.

- FR-100: Definir búsqueda/lista/mapa, comparación de dos, selección manual sin GPS y lecturas públicas offline con fecha y vacíos recuperables.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5/6; H08/H10.

### Historias de consumo por intención

- FR-225: Consumir EP-025 para buscar y filtrar prestadores por necesidad y zona, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-226: Consumir EP-026 para autocompletar servicios y términos reconocidos, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-227: Consumir EP-027 para comparar exactamente dos prestadores, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-228: Consumir EP-028 para buscar lugar para seleccionar ubicación, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-229: Consumir EP-029 para obtener etiqueta de zona desde punto, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-230: Consumir EP-030 para componer inicio por zona y modo, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.

### Funcionalidades y obligaciones con dueño explícito

- FR-506: M06 Inicio solicitante: Actor Solicitante/visitante: Feed, categorías, trabajos cercanos, necesidades propias y pedidos.
- FR-507: M07 Inicio prestador: Actor Prestador: Comunidad, oportunidades, pendientes y acceso a perfil propio.
- FR-508: M08 Buscar prestadores: Actor Solicitante: SearchBar, sugerencias, recientes locales, chips, filtros, orden y mapa/lista.
- FR-510: M10 Selector geográfico: Actor Todos: Mapa, pin, zoom, buscar dirección, usar GPS, radio y restablecer.
- FR-512: M12 Comparación: Actor Cuenta: Dos columnas de condiciones, precio, modalidad y confianza.

- FR-708: Corregir H08: Comparación equivalente; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-07/spec.md).

S02/G01: filtros normalizados, read_cache con expiresAt comprobado por lector, cursor estable y DTO público. App: recientes y resúmenes públicos; no origen privado ni contactos cacheados.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Tercer prestador en comparación se rechaza.
- [ ] AC-002: Sin GPS permite selector manual; vacío explica ampliar/cambiar zona.
- [ ] AC-003: Precio de electricidad no gana frente a plomería por ser numéricamente menor.

- [ ] AC-090 → FR-090/NFR-090: H08/H10: comparar solo serviceKey/unidad/moneda/materiales; local con radio cero aparece; denegar GPS conserva entrada manual; edición invalida caché entre réplicas.

- [ ] AC-100 → FR-100/NFR-100: Denegar GPS no bloquea explorar; dato local muestra antigüedad y refresco; solo se muestra mejor precio si comparable=true con conceptos equivalentes; contacto privado no vive en caché pública.

- [ ] AC-225 → FR-225/NFR-001/NFR-003: EP-025: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Cobertura real por prestador; orden estable; ubicación exacta no sale La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-226 → FR-226/NFR-001/NFR-003: EP-026: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Tokens/prefijos indexados; debounce móvil; excluir búsqueda privada histórica La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-227 → FR-227/NFR-001/NFR-003: EP-027: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Evitar inventar precio u horario faltante; route estática antes de {id}; destacar precio menor solo si servicio, moneda, unidad y materiales/alcance coinciden; de lo contrario no comparable y sin MEJOR. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-228 → FR-228/NFR-001/NFR-003: EP-028: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Adaptador Azure Maps; comprobar licencia/cupos; limitar precisión pública La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-229 → FR-229/NFR-001/NFR-003: EP-029: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No guardar consultas precisas en logs o caché pública sin anonimizar La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-230 → FR-230/NFR-001/NFR-003: EP-030: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Gateway agrega DTO públicos; para mine exige usuario; fallos parciales explícitos; conservar trabajo cercano por cobertura de prestador o distancia del trabajo <=3 km según postNear, usando ubicación privada solo dentro del servidor. La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-506 → FR-506/NFR-002/NFR-003: Estados públicos y privados según sesión. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-507 → FR-507/NFR-002/NFR-003: Oportunidades por capacidad/cobertura y pedidos del usuario. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-508 → FR-508/NFR-002/NFR-003: Sin resultados, ampliar zona y condiciones faltantes explícitas. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-510 → FR-510/NFR-002/NFR-003: Permiso denegado permite elegir manualmente. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-512 → FR-512/NFR-002/NFR-003: Máximo dos, marcar datos no indicados. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-708 → FR-708/NFR-001/NFR-003: Precio menor solo se destaca con servicio, unidad, moneda, alcance/materiales equivalentes; si falta dato, no comparable con razón.

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

La [spec 016 de sincronización local](../016-sincronizacion-local/spec.md) es autoridad del comportamiento transversal de cola/migraciones/conflictos; este recorrido conserva sus reglas de negocio y contratos, sin duplicar su implementación.

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
| NFR-001 | T-010, T-011, T-004, T-225, T-226, T-227, T-228, T-229, T-230, T-708 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-225, AC-226, AC-227, AC-228, AC-229, AC-230, AC-708 |
| NFR-002 | T-001, T-007, T-005, T-506, T-507, T-508, T-510, T-512 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-506, AC-507, AC-508, AC-510, AC-512 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-225, T-226, T-227, T-228, T-229, T-230, T-506, T-507, T-508, T-510, T-512, T-708 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-225, AC-226, AC-227, AC-228, AC-229, AC-230, AC-506, AC-507, AC-508, AC-510, AC-512, AC-708 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-225 | T-225 | AC-225 |
| FR-226 | T-226 | AC-226 |
| FR-227 | T-227 | AC-227 |
| FR-228 | T-228 | AC-228 |
| FR-229 | T-229 | AC-229 |
| FR-230 | T-230 | AC-230 |
| FR-506 | T-506 | AC-506 |
| FR-507 | T-507 | AC-507 |
| FR-508 | T-508 | AC-508 |
| FR-510 | T-510 | AC-510 |
| FR-512 | T-512 | AC-512 |
| FR-708 | T-708 | AC-708 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
