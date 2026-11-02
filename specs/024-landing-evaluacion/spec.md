# 024-LANDING-EVALUACION — Landing y evaluación

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `024-landing-evaluacion`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md). Contraparte: [spec](../../../API_NexoLocal/specs/nv-23/spec.md).

## 2. Objetivo

Coordinar artefacto web, enlaces Play/aviso/borrado, Analytics, QR y expediente.

## 3. Alcance / Fuera de alcance

Dependencias: 014 prepara Play; 012/023 privacidad; nv-23. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Coordinar artefacto web, enlaces Play/aviso/borrado, Analytics, QR y expediente.
- FR-002: Aplicar la regla: Web con dueño separado; Flutter comprueba handoff, no administra hosting/GA4.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Play instala versión esperada; aviso/borrado/QR funcionan; evento GA4 se prueba en landing sin PII.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Funcionalidades y obligaciones con dueño explícito

- FR-528: W01 landing: Landing pública con descripción del producto, enlace Play, aviso/manejo de datos y eliminación, Analytics y QR conforme a destino final.
- FR-417: R17 Landing/Analytics: Atender el requisito académico 17 en su superficie y coordinar la contraparte.
- FR-419: R19 Paquete y evaluación: Atender el requisito académico 19 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. Web con dueño separado; Flutter comprueba handoff, no administra hosting/GA4.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Play instala versión esperada; aviso/borrado/QR funcionan; evento GA4 se prueba en landing sin PII.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: Web con dueño separado; Flutter comprueba handoff, no administra hosting/GA4. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-528 → FR-528/NFR-002/NFR-003: Verificar enlaces finales, instalación Play en contraparte, privacidad/eliminación, evento GA4 sin PII y decode del QR renderizado; no afirmar ejecución por documentación.
- [ ] AC-417 → FR-417/NFR-002/NFR-003: Landing pública con Play/aviso/datos/eliminación, hosting permitido y Analytics verificable sin PII; coordinar correo/titular reales. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.
- [ ] AC-419 → FR-419/NFR-002/NFR-003: Preparar .rar y scripts DB reproducibles sin secretos, evidencia de equipo y evaluación indicada para 02/12/2026; no inventar entrevistas ni aportaciones. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Play instala versión esperada; aviso/borrado/QR funcionan; evento GA4 se prueba en landing sin PII.

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
| NFR-001 | T-010, T-011, T-004 | AC-001, AC-002, AC-100 |
| NFR-002 | T-001, T-007, T-005, T-528, T-417, T-419 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-417, AC-419, AC-528 |
| NFR-003 | T-002, T-012, T-003, T-005, T-528, T-417, T-419 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-417, AC-419, AC-528 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-528 | T-528 | AC-528 |
| FR-417 | T-417 | AC-417 |
| FR-419 | T-419 | AC-419 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
