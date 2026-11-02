# 014-ENTREGA — Infraestructura, landing, DevSecOps y publicación

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `014-entrega`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Aplicación: Constitución §§5/7/8/9/11; D05/D07/D08.

Infraestructura, landing, DevSecOps y publicación. Servicios involucrados: G01, S01-S07, Flutter, Landing.

No incluye implementación de dominios ajenos ni afirma integraciones ya existentes.

## 2. Objetivo

Infraestructura, landing, DevSecOps y publicación

## 3. Alcance / Fuera de alcance

Requisitos Móvil v2: 01, 02, 03, 05, 06, 07, 08, 09, 11, 12, 13, 14, 15, 16, 17, 18, 19. Componentes: W01, M26, M27. Hallazgos: Sin hallazgo específico asociado.

Dependencias: Preparación desde 001..004; cierre requiere 004..013, 016-sincronizacion-local y backend listo; 015 opcional.

Fuera: lógica/persistencia directa del backend, Razor y cookies web.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Equipo prepara artefacto móvil trazable y comprueba compatibilidad con backend desplegado; la app no administra réplicas.
- FR-002: Instalar desde Play y coordinar enlaces/landing/evaluación con 024; publicación de web tiene dueño separado.

- NFR-001: autorización, aislamiento, privacidad y manejo de errores según constitución.
- NFR-002: trazabilidad y evidencia real; no declarar integraciones reales con dobles.
- NFR-003: calidad y verificación del recorrido según plan/checklist.

Reglas del recorrido:
- No posponer Play/CI hasta el final; comenzar con primera vertical, cerrar aquí evidencia global.
- Nube y costo cero requieren cuenta/región/cotización; no asumir gratuidad.
- MCP es opcional; entrevistas y referencias docentes requieren evidencia real.

- FR-090: Definir firma/versionName/versionCode, canal Play, permisos/aviso/borrado y enlaces landing; cerrar instalación y expediente de evaluación.
- NFR-090: Frontera, fallos y evidencia según acuerdo común; Reproducir instalación Play y compatibilidad API, logs sin PII, atención por dos réplicas, rollback, .rar limpio y scripts DB; métricas GA4 sin datos personales y QR final decodificado.

- FR-100: Definir artefacto firmado, versionName/versionCode, compatibilidad API, canal Play y expediente móvil; coordinar landing/aviso/eliminación/GA4/QR con dueño web.
- NFR-100: Verificación específica del propietario y límites de la contraparte según Constitución §§5/7/8/9/11; D05/D07/D08.

### Funcionalidades y obligaciones con dueño explícito

- FR-401: R01 Instalación desde Play: Atender el requisito académico 1 en su superficie y coordinar la contraparte.
- FR-408: R08 CI/CD: Atender el requisito académico 8 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo/pantallas](../../docs/endpoints-ui.md) y [contratos del backend](../../../API_NexoLocal/docs/endpoints.md).

### Frontera y fuentes

[Acuerdo común](../../../docs_nexo/SDD_ALINEACION.md), [fuentes y cobertura](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [flujo Codex/Claude](../../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Contraparte: [spec relacionada](../../../API_NexoLocal/specs/nv-14/spec.md).

Manifiesto por artefacto, contrato, evento y schemaVersion; scripts DB idempotentes, índices/restauración; cuentas, costos, llaves y responsables fuera del documento público. Landing es componente separado.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Balanceo alcanza dos instancias y logout revoca en ambas.
- [ ] AC-002: Pipeline conserva versiones, pruebas, trazas, rollback y configuración sin secretos.
- [ ] AC-003: Play, privacidad, eliminación, GA4/consentimiento y QR comprobados en destino final.

- [ ] AC-090 → FR-090/NFR-090: Reproducir instalación Play y compatibilidad API, logs sin PII, atención por dos réplicas, rollback, .rar limpio y scripts DB; métricas GA4 sin datos personales y QR final decodificado.

- [ ] AC-100 → FR-100/NFR-100: Instalar desde Play muestra versión esperada, permisos/aviso y ruta de borrado operativos; no se afirma despliegue backend por compilar AAB; enlaces/QR y GA4 requieren comprobación propia de landing.

- [ ] AC-401 → FR-401/NFR-002/NFR-003: Descargar e instalar desde Google Play la versión firmada y registrar dispositivo/versiones y compatibilidad API. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-408 → FR-408/NFR-002/NFR-003: Definir pipelines backend y móvil, artefactos inmutables/manifiesto, permisos mínimos, despliegue y rollback con evidencia real. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

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
| NFR-001 | T-010, T-011, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| NFR-002 | T-001, T-007, T-005, T-401, T-408 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-401, AC-408 |
| NFR-003 | T-002, T-010, T-011, T-021, T-003, T-005, T-401, T-408 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-401, AC-408 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-090, AC-100 |
| FR-401 | T-401 | AC-401 |
| FR-408 | T-408 | AC-408 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
