# 006-PERFILES — Perfiles, catálogo, cobertura y edición

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `006-perfiles`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§1/2/4/5; H06/H07/H09/H10.

Perfiles, catálogo, cobertura y edición. Servicios involucrados: S02, S06.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Perfiles, catálogo, cobertura y edición

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 04, 09, 14, 15, 16. Componentes: M04, M10, M11, M21. Hallazgos: H06, H07, H09, H10.

Dependencias: 004-identidad-sesion, 005-contenido-seguro y nv-06.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cuenta crea perfil persona/negocio y completa después los opcionales.
- FR-002: Prestador modifica horarios/precios/condiciones; integra contacto de 025 y cuenta personal de 017.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- Una política versionada calcula completitud en alta y perfil.
- Separar fotos/publicaciones/pedidos completados; radio cero es válido para solo local.
- Origen domiciliario privado; dirección comercial pública solo por intención explícita.

- FR-090: Diseñar alta básica y edición posterior con opcionales omitibles, selector geográfico y resumen de completitud recibido del backend.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; H06/H07/H09/H10: mismo porcentaje/policyVersion en alta y perfil, fotos no cuentan como trabajos, radio cero solo local y edición siempre accesible.

- FR-100: Definir formularios de alta/edición de persona/negocio, opcionales omitibles, acceso permanente y estado canónico de completitud/contacto recibido del backend.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§1/2/4/5; H06/H07/H09/H10.

### Historias de consumo por intención

- FR-216: Consumir EP-016 para crear perfil de persona o negocio, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-217: Consumir EP-017 para consultar perfil público y señales, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-218: Consumir EP-018 para consultar perfil editable y completitud, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-219: Consumir EP-019 para actualizar datos comerciales y servicios, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-220: Consumir EP-020 para editar modalidad y zona de atención, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-221: Consumir EP-021 para configurar horarios y urgencias, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-222: Consumir EP-022 para definir visita y precios orientativos, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-223: Consumir EP-023 para confirmar vigencia de información, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Previsto en línea base; contrato formal y aceptación pendientes.
- FR-224: Consumir EP-024 para retirar perfil de publicación, desde la intención autorizada de esta capacidad; no inventar otra pantalla o ruta. Complemento de diseño; condición/UX y alcance se ratifican antes de Ready, sin pantalla inventada.

### Funcionalidades y obligaciones con dueño explícito

- FR-504: M04 Registro prestador: Actor Persona/negocio: Persona o negocio; responsable, modalidad, categoría/actividad, cobertura; opcionales: horarios, tres precios, condiciones y seis fotos de portafolio.
- FR-511: M11 Perfil público: Actor Todos: Portada/avatar, señales, datos, pestañas Trabajos/Información/Opiniones, contacto y dirección comercial.
- FR-521: M21 Cuenta y edición: Actor Cuenta: Cambio de modo, perfil, horarios/precios/condiciones, completitud, intereses y actividad.

- FR-706: Corregir H06: Completitud única; integrar propietarios implicados sin duplicar regla.

- FR-707: Corregir H07: Contadores honestos; integrar propietarios implicados sin duplicar regla.

- FR-709: Corregir H09: Edición permanente; integrar propietarios implicados sin duplicar regla.

- FR-710: Corregir H10: Modalidad solo local; integrar propietarios implicados sin duplicar regla.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-06/spec.md).

S02: categories, providers y read_cache; perfil por cuenta único, GeoJSON [longitud,latitud], origen privado y dirección comercial explícita. Límites: tres precios y seis fotos de portafolio.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Alta básica funciona sin fotos/precios; siete fotos conserva máximo seis.
- [ ] AC-002: Horario cierre<=apertura y visita pagada sin monto se rechazan.
- [ ] AC-003: Después de completar horario/precio sigue existiendo acceso a editar.
- [ ] AC-004: Respuesta pública no contiene privateOrigin ni teléfono no permitido.

- [ ] AC-090 → FR-090/NFR-090: H06/H07/H09/H10: mismo porcentaje/policyVersion en alta y perfil, fotos no cuentan como trabajos, radio cero solo local y edición siempre accesible.

- [ ] AC-100 → FR-100/NFR-100: Alta básica no exige foto/horario/precio opcionales; editar después sigue accesible; solo local no anuncia cobertura a domicilio; tres precios y seis fotos se validan sin contar fotos como trabajos.

- [ ] AC-216 → FR-216/NFR-001/NFR-003: EP-016: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Un perfil por cuenta; mínimos de registro; texto/medios aprobados; portafolio de registro hasta seis fotos aprobadas; no contar fotos como trabajos ni reutilizar providerId=me entre cuentas. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-217 → FR-217/NFR-001/NFR-003: EP-017: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Ocultar origen privado y datos de cuenta; teléfono según permisos La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-218 → FR-218/NFR-001/NFR-003: EP-018: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Solo propio; completitud se calcula desde campos persistidos La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-219 → FR-219/NFR-001/NFR-003: EP-019: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Máximo tres precios orientativos en UI inicial; catálogo/categorías aparte; contenido moderado; editor permanente permite corregir campos completos, no solo faltantes. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-220 → FR-220/NFR-001/NFR-003: EP-020: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Validar rango de coordenadas y radio positivo en dom/ambos, cero permitido en local; publicación comercial explícita La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-221 → FR-221/NFR-001/NFR-003: EP-021: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Cierre posterior a apertura para alcance inicial; validar zona IANA La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-222 → FR-222/NFR-001/NFR-003: EP-022: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Cero representa visita gratis; ausencia no equivale a cero; tres filas visibles; no comparar montos de unidades distintas. La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-223 → FR-223/NFR-001/NFR-003: EP-023: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; No aumentar reputación por pulsar actualizar La UI refleja la regla del servidor, no la sustituye.
- [ ] AC-224 → FR-224/NFR-001/NFR-003: EP-024: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Ampliación operativa; definir tratamiento de pedidos abiertos y vínculos La UI refleja la regla del servidor, no la sustituye.

- [ ] AC-504 → FR-504/NFR-002/NFR-003: Terminar básico y completar después sin perder datos. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-511 → FR-511/NFR-002/NFR-003: Sin domicilio privado en DTO ni mapa público. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-521 → FR-521/NFR-002/NFR-003: Modo no permite suplantación y métricas no prometen ventas. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.

- [ ] AC-706 → FR-706/NFR-001/NFR-003: Alta/perfil/cuenta reciben la misma política versionada sobre los mismos datos; fórmula por ratificar sin porcentajes inventados.

- [ ] AC-707 → FR-707/NFR-001/NFR-003: Fotos de portafolio, publicaciones, pedidos resueltos y recomendaciones son contadores distintos; seis fotos no equivalen a seis servicios.

- [ ] AC-709 → FR-709/NFR-001/NFR-003: Tras completar horario/precios/condiciones/contacto se conserva acceso a editar y respuesta actualiza vistas/caché.

- [ ] AC-710 → FR-710/NFR-001/NFR-003: Radio cero en local no vuelve invisible negocio ni muestra menos de 0 km a domicilio; selector y búsqueda respetan modalidad.

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
| NFR-001 | T-010, T-011, T-004, T-216, T-217, T-218, T-219, T-220, T-221, T-222, T-223, T-224, T-706, T-707, T-709, T-710 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-216, AC-217, AC-218, AC-219, AC-220, AC-221, AC-222, AC-223, AC-224, AC-706, AC-707, AC-709, AC-710 |
| NFR-002 | T-001, T-007, T-005, T-504, T-511, T-521 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-504, AC-511, AC-521 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-216, T-217, T-218, T-219, T-220, T-221, T-222, T-223, T-224, T-504, T-511, T-521, T-706, T-707, T-709, T-710 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100, AC-216, AC-217, AC-218, AC-219, AC-220, AC-221, AC-222, AC-223, AC-224, AC-504, AC-511, AC-521, AC-706, AC-707, AC-709, AC-710 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-004, AC-090, AC-100 |
| FR-216 | T-216 | AC-216 |
| FR-217 | T-217 | AC-217 |
| FR-218 | T-218 | AC-218 |
| FR-219 | T-219 | AC-219 |
| FR-220 | T-220 | AC-220 |
| FR-221 | T-221 | AC-221 |
| FR-222 | T-222 | AC-222 |
| FR-223 | T-223 | AC-223 |
| FR-224 | T-224 | AC-224 |
| FR-504 | T-504 | AC-504 |
| FR-511 | T-511 | AC-511 |
| FR-521 | T-521 | AC-521 |
| FR-706 | T-706 | AC-706 |
| FR-707 | T-707 | AC-707 |
| FR-709 | T-709 | AC-709 |
| FR-710 | T-710 | AC-710 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
