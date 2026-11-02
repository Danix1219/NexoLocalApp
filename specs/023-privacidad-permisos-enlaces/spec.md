# 023-PRIVACIDAD-PERMISOS-ENLACES — Privacidad, permisos y enlaces

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `023-privacidad-permisos-enlaces`

## 1. Contexto

Constitución: [rectora](../../constitution.md), §§1–8/11. Desglose de funciones existentes, sin app creada. [Acuerdo](../../../docs_nexo/SDD_ALINEACION.md) y [fuentes](../../../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md).

## 2. Objetivo

Aviso/consentimiento, permisos Android en contexto y compartir/copiar/ruta autorizados.

## 3. Alcance / Fuera de alcance

Dependencias: 001/003/004; contacto 025 y borrado 012. Fuera: bases remotas directas, superficies internas/admin, código ahora y pantallas inventadas por endpoint.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Aviso/consentimiento, permisos Android en contexto y compartir/copiar/ruta autorizados.
- FR-002: Aplicar la regla: No endpoint por control local ni permisos indiscriminados; destino vuelve a autorizar.
- FR-003: Integrar y recuperar sin cambiar propiedad de datos.
- FR-090: Refinar historias con fuente, actor, precondición, contrato/revisión y exclusiones.
- FR-100: Resolver el escenario: Permiso denegado ofrece alternativa; compartir no incluye PII; deep link no revela domicilio revocado.
- NFR-001: Aislamiento por identidad/recurso/estado y datos mínimos según constitución.
- NFR-002: Evidencia documental, doble e integración real diferenciadas; revisión humana pendiente.
- NFR-003: Errores, reintentos y compatibilidad definidos antes de implementar.
- NFR-090: Sin proveedor/costo/stack/firma supuestos como ratificados.
- NFR-100: Este desglose no añade servicios, endpoints o pantallas por sí mismo.

### Funcionalidades y obligaciones con dueño explícito

- FR-524: M24 Privacidad y sesión: Actor Cuenta: Aviso, términos, eliminar con reautenticación, logout y estado de trámite.
- FR-527: M27 Compartir, copiar y ruta: Actor Cuenta según acción: Compartir perfil, copiar número autorizado y abrir navegación del sistema.
- FR-416: R16 Móvil completo: Atender el requisito académico 16 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo](../../docs/endpoints-ui.md), [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). Enlazar revisión por historia; no copiar payloads. [Modelo local](../../docs/modelo-datos.md): cuenta aislada y token fuera de SQLite. No endpoint por control local ni permisos indiscriminados; destino vuelve a autorizar.

## 6. Criterios de aceptación verificables

- [ ] AC-001: Permiso denegado ofrece alternativa; compartir no incluye PII; deep link no revela domicilio revocado.
- [ ] AC-002: Actor sin permiso no ejecuta ni recibe campos privados; permitido obtiene solo resultado del contrato.
- [ ] AC-003: Fallo/reintento/dependencia caída conserva consistencia y no confirma éxito ficticio.
- [ ] AC-090: Cada historia identifica entrada/salida, precondición, revisión de contrato y evidencia esperada.
- [ ] AC-100: No endpoint por control local ni permisos indiscriminados; destino vuelve a autorizar. Verificar caso positivo, negativo y recuperación pertinente con evidencia real cuando haya producto.

- [ ] AC-524 → FR-524/NFR-002/NFR-003: Sin credenciales o datos privados residuales tras salir. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-527 → FR-527/NFR-002/NFR-003: Enlaces verificados y acceso a domicilio según estado. Verificar estados carga/vacío/error/red y permisos/accesibilidad aplicables sin simular aceptación remota.
- [ ] AC-416 → FR-416/NFR-002/NFR-003: Demostrar moderación antes de persistir, push, aviso/datos/borrado, permisos, continuidad de sesión, SQLite/sincronización aplicable y funciones ML y GenAI reales distintas. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

## 7. Riesgos y deudas documentadas

D01–D08 pertinentes pendientes; bibliotecas/proveedor y Android real no validados. Permiso denegado ofrece alternativa; compartir no incluye PII; deep link no revela domicilio revocado.

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
| NFR-002 | T-001, T-007, T-005, T-524, T-527, T-416 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-416, AC-524, AC-527 |
| NFR-003 | T-002, T-012, T-003, T-005, T-524, T-527, T-416 | AC-001, AC-002, AC-003, AC-090, AC-100, AC-416, AC-524, AC-527 |
| NFR-090 | T-006, T-007 | AC-090 |
| NFR-100 | T-020, T-021, T-004 | AC-002, AC-100 |
| FR-524 | T-524 | AC-524 |
| FR-527 | T-527 | AC-527 |
| FR-416 | T-416 | AC-416 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
