# 016-SINCRONIZACION-LOCAL — Persistencia local, offline y reconciliación

Versión: 0.4.0 | Fecha: 2026-11-02 | Rama prevista: `016-sincronizacion-local`

## 1. Contexto

Constitución rectora: [constitution.md](../../constitution.md), §§1–8. La [fuente 1.2.0](../../../docs_nexo/Nexo_Local_Requerimientos_y_Arquitectura.md), sección 16 «SQLite y sincronización» y «Límites offline», exige lectura local y sincronización aplicable. El diseño estaba disperso sin un incremento verificable que cubriera cola, migraciones, conflictos y cambio de cuenta.

## 2. Objetivo

Mantener consultas útiles sin conexión y reconciliar únicamente acciones permitidas, preservando aislamiento y autoridad del servidor. No ampliar funcionalidades de negocio ni inventar endpoints.

## 3. Alcance / Fuera de alcance

Requisito académico 09 y 16; M20/M24/M26; H03. Dependencias: 003-contratos-consumo y 004-identidad-sesion para fundamento; 007-descubrimiento y 008-comunidad para integración de consultas/guardados. Backend nv-04/nv-06/nv-07/nv-08 mantiene contratos y autorización.

Fuera: aceptar/resolver pedidos offline, publicación sin moderación, confirmación de mensaje sin servidor, almacenamiento de tokens en SQLite, acceso directo a bases remotas y migraciones ejecutables en esta fase.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Consultar catálogo y resúmenes públicos locales con origen, fecha, caducidad y refresco al reconectar.
- FR-002: Sincronizar guardados con PUT/DELETE idempotentes y conservar borradores privados sin declararlos publicados.
- FR-003: Definir esquema local, migración recuperable, cola permitida, reintentos acotados, conflicto y limpieza al cambiar de cuenta.
- NFR-001: Particionar datos privados y operaciones por userId/sesión; nunca reutilizar cola de otra cuenta ni entregar contacto revocado desde caché.
- NFR-002: Distinguir pruebas locales con doble, SQLite real y sincronización con API; conservar evidencia por criterio.
- NFR-003: Recuperación tras cierre de proceso o error de migración preserva consistencia sin simular confirmación remota.
- FR-090: Documentar allowlist de operaciones en cola, operationId/clave estable, versión base, estado y política de descarte/reintento por contrato.
- NFR-090: Timeout no demuestra fallo; resultado incierto se consulta/reintenta solo con semántica idempotente formalizada.
- FR-100: Reconciliar respuesta tardía, token revocado y cambio de cuenta sin reinsertar datos retirados ni ejecutar intención de sesión anterior.
- NFR-100: No conservar credenciales de acceso general para gestionar pendientes tras logout; protección y retención local requieren D02/D05.

### Funcionalidades y obligaciones con dueño explícito

- FR-409: R09 Caché en tres niveles: Atender el requisito académico 9 en su superficie y coordinar la contraparte.

## 5. Contratos (rutas, config, env)

[Consumo móvil](../../docs/endpoints-ui.md) y [autoridad API](../../../API_NexoLocal/docs/contracts/README.md). EP-014/017/025 y lecturas elegidas sirven datos públicos según DTO; EP-038/039/040 cubren guardados por cuenta. La lista no autoriza implementar todas las lecturas. No duplicar payloads.

Para PATCH de perfil, If-Match/versiones se formaliza en su historia antes de encolarlo; hasta entonces no entra en allowlist. Publicación/mensaje usa la política del recorrido y confirmación durable, nunca se aprueba offline. [Modelo local](../../docs/modelo-datos.md) y [acuerdo común](../../../docs_nexo/SDD_ALINEACION.md).

## 6. Criterios de aceptación verificables

- [ ] AC-001: Sin red se muestra último resumen público con fecha y no se simula contenido cuando no existe caché.
- [ ] AC-002: Repetir guardado con misma identidad/clave no crea duplicados; reintento conserva intención y confirma estado remoto.
- [ ] AC-003: Conflicto 409/versión antigua refresca y presenta resolución; no sobrescribe silenciosamente el cambio remoto.
- [ ] AC-004: Ana cierra sesión antes de sincronizar y Carlos entra: no se sube ni se muestra información privada de Ana.
- [ ] AC-005: Migración local interrumpida tiene recuperación definida y comprobable con SQLite real; no borra datos arbitrariamente ni registra éxito ficticio.
- [ ] AC-006: Aceptar/resolver pedido y revelar contacto quedan indisponibles offline; borrador/publicación/mensaje conserva estado pendiente hasta acuse autorizado.
- [ ] AC-090 → FR-090/NFR-090: Cada operación permitida tiene clave, versión, error, límites de reintento y regla de conflicto definidos por contrato; lo no permitido no se reenvía.
- [ ] AC-100 → FR-100/NFR-100: Una respuesta que llega después de logout/cancelación/cambio de cuenta no repuebla caché privada ni inicia reenvío de sesión anterior.

- [ ] AC-409 → FR-409/NFR-002/NFR-003: Demostrar caché DB/backend/frontend con hit/miss, caducidad, invalidación y aislamiento; no llamar caché solo al buffer del motor. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas.

## 7. Riesgos y deudas documentadas

SDK SQLite/protección, estrategia de migración y límites concretos pendientes de D02/D05. Concretar con tamaños/uso reales antes de Ready. Contratos formales y prueba Android siguen pendientes. Un test con repositorio en memoria no prueba SQLite ni seguridad del teléfono.

## Aprobación y Control de Cambios

Estado: Borrador documental; sin implementación ni evidencia de producto.
Revisores: por asignar. Fecha: pendiente.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.3.0 | 2026-11-02 | Asistente, sin firma humana | Incremento explícito para offline/migraciones/reconciliación existentes en fuente |

La tabla define cobertura de diseño, no pruebas ejecutadas. El plan concreta método/entorno; el checklist registra evidencia y revisión humana. Los escenarios compartidos no trasladan la propiedad del backend a Flutter.

La traza acredita asignación documental, no pruebas ejecutadas. Las operaciones internas/admin y opcionales mantienen límites expresos.

## Integración y límites del desglose

Las historias de EP tienen un único dueño primario en el inventario y mapa bilateral; los requisitos agregados previos de fases origen verifican integración con sus subcapacidades. No son una segunda implementación. Una dependencia de cierre de experiencia integrada no impide construir el subset anterior que sí tiene contratos/entradas. Las condiciones bloqueantes específicas se resuelven antes de Ready de cada historia.

## Trazabilidad del incremento

| Requisito local | Tareas definidas | Criterios vinculados |
|---|---|---|
| FR-001 | T-001, T-002, T-010, T-003 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 |
| FR-002 | T-001, T-002, T-011, T-003 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 |
| FR-003 | T-001, T-002, T-012, T-003 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 |
| NFR-001 | T-010, T-011, T-012, T-004 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 |
| NFR-002 | T-001, T-007, T-005, T-409 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100, AC-409 |
| NFR-003 | T-002, T-010, T-011, T-012, T-021, T-003, T-005, T-409 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100, AC-409 |
| FR-090 | T-006, T-007 | AC-090 |
| NFR-090 | T-006, T-007 | AC-090 |
| FR-100 | T-020, T-021 | AC-100 |
| NFR-100 | T-020, T-021, T-004 | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 |
| FR-409 | T-409 | AC-409 |

Cobertura de diseño, no ejecución aprobada. Contratos formales, decisiones y evidencia real siguen pendientes.
