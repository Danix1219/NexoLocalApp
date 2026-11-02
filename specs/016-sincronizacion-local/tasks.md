# TAREAS — 016-sincronizacion-local

Spec: [spec.md](spec.md). Plan: [plan.md](plan.md). Constitución: [rectora](../../constitution.md).

Estado: documentación propuesta; todas las casillas pendientes. Preparación documental y ejecución futura son distintas. Un encargo posterior de implementación y Ready de la historia son necesarios antes de construir producto. IDs locales; al citar usar contexto/spec/T-ID.

## Fase A — Refinamiento y decisiones

- [ ] T-006 →FR-090,NFR-090. Documentar allowlist de operaciones en cola, operationId/clave estable, versión base, estado y política de descarte/reintento por contrato. Acepta: AC-090 tiene precondición, resultado, fuente, contraparte y evidencia esperada definidos; decisiones pertinentes D01–D08 registradas sin firmas ficticias. Depende de: fuentes y dependencias explícitas en spec; sin dependencia de construcción local.
- [ ] T-020 →FR-100,NFR-100. Desglosar el escenario propio: Reconciliar respuesta tardía, token revocado y cambio de cuenta sin reinsertar datos retirados ni ejecutar intención de sesión anterior. Acepta: AC-100 documenta caso positivo, negativo, fallo/reintento y responsable de cada superficie; exclusiones identificadas. Depende de: T-006.
- [ ] T-001 →FR-001,FR-002,FR-003,NFR-002. Preparar Ready de una historia acotada. Acepta: requisitos y AC seleccionados, contratos pertinentes formalizados antes de consumo, decisiones bloqueantes resueltas, revisión humana identificada y plan/tareas conciliados; sin declarar Ready por lint. Depende de: T-006, T-020 y entradas de la spec; no requiere completar todo el dominio.

## Fase B — Entregable y ejecución posterior

- [ ] T-002 →FR-001,FR-002,FR-003,NFR-003. Preparar el cambio del propietario con archivos reales al encargar implementación. Acepta: la historia seleccionada tiene archivos, versión, permisos y orden de cambio concretos; el estado documental no se presenta como aplicación creada. Depende de: T-001 y encargo correspondiente si hay ejecución de producto.
- [ ] T-010 →FR-001,NFR-001,NFR-003. Atender el requisito propio: Consultar catálogo y resúmenes públicos locales con origen, fecha, caducidad y refresco al reconectar. Acepta: AC-001 verificados con evidencia del alcance aplicable, incluyendo rechazo/fallo y sin sustituir integración real por doble; en diseño queda procedimiento pendiente explícito. Depende de: T-002 y contrato/decisiones de esa historia.
- [ ] T-011 →FR-002,NFR-001,NFR-003. Atender el requisito propio: Sincronizar guardados con PUT/DELETE idempotentes y conservar borradores privados sin declararlos publicados. Acepta: AC-002, AC-004, AC-006 verificados con evidencia del alcance aplicable, incluyendo rechazo/fallo y sin sustituir integración real por doble; en diseño queda procedimiento pendiente explícito. Depende de: T-002 y contrato/decisiones de esa historia.
- [ ] T-012 →FR-003,NFR-001,NFR-003. Atender el requisito propio: Definir esquema local, migración recuperable, cola permitida, reintentos acotados, conflicto y limpieza al cambiar de cuenta. Acepta: AC-003, AC-004, AC-005, AC-006 verificados con evidencia del alcance aplicable, incluyendo rechazo/fallo y sin sustituir integración real por doble; en diseño queda procedimiento pendiente explícito. Depende de: T-002 y contrato/decisiones de esa historia.
- [ ] T-021 →FR-100,NFR-100,NFR-003. Comprobar el escenario específico. Acepta: AC-100 — Una respuesta que llega después de logout/cancelación/cambio de cuenta no repuebla caché privada ni inicia reenvío de sesión anterior. Registrar resultado real o pendiente sin inventar ejecución. Depende de: T-020 y T-002; evidencia de producto solo tras implementación autorizada.
- [ ] T-003 →FR-001,FR-002,FR-003,NFR-003. Integrar frontera y datos reales de la historia. Acepta: AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 cuentan con comprobación de consumidor/provider, almacenamiento o dispositivo según superficie; fundamentos pueden producir evidencia documental identificada sin afirmar integración. Depende de: T-010, T-011, T-012, T-021, T-409.
- [ ] T-004 →NFR-001,NFR-100. Revisar privacidad, permisos, aislamiento, errores y fallos pertinentes. Acepta: AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 incluyen escenarios negativos; autoridad por recurso/estado se comprueba en API y presentación/limpieza en app; ninguna PII o credencial en evidencia. Depende de: T-003.
- [ ] T-007 →FR-090,NFR-090,NFR-002. Verificar el criterio transversal de la fase. Acepta: AC-090 — Cada operación permitida tiene clave, versión, error, límites de reintento y regla de conflicto definidos por contrato; lo no permitido no se reenvía. Distinguir revisión documental de ejecución futura. Depende de: T-004; preparación del escenario ya en T-006.

## Fase C — Cierre y revisión

- [ ] T-005 →NFR-002,NFR-003. Conciliar documentos, ejecutar gates pertinentes y actualizar Memoria. Acepta: AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-090, AC-100 tienen resultado/evidencia o pendiente explícito; salida/exit, entorno, limitación y revisor reales registrados; sin aprobación automática. Depende de: T-004, T-007 y checklist del incremento.

## Verificación disponible

Hoy: powershell -NoProfile -File scripts/check_sdd.ps1 desde la raíz correspondiente, más revisión de integridad de IDs y dependencias. Solo documental. Build/test/proveedores/Android no ejecutados por esta fase.

## Funcionalidades y obligaciones verificables

- [ ] T-409 →FR-409,NFR-002,NFR-003. Definir y atender R09 Caché en tres niveles. Acepta: AC-409: Demostrar caché DB/backend/frontend con hit/miss, caducidad, invalidación y aislamiento; no llamar caché solo al buffer del motor. App entrega consumo/experiencia y enlaza evidencia del backend/web; no replica infraestructura ni lee bases remotas. Planear método de comprobación, entorno/responsable y evidencia; no aprobar mientras falten decisiones/contratos o ejecución real cuando corresponda. Evidencia real cuando corresponda; diseño solo no acredita aceptación. Depende de: T-002 y entradas/decisiones de la historia; trabajo documental previo no requiere código.
