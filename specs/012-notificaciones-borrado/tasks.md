# TAREAS — 012-notificaciones-borrado

Spec: [spec.md](spec.md). Plan: [plan.md](plan.md). Constitución: [rectora](../../constitution.md).

Estado: documentación propuesta; todas las casillas pendientes. Preparación documental y ejecución futura son distintas. Un encargo posterior de implementación y Ready de la historia son necesarios antes de construir producto. IDs locales; al citar usar contexto/spec/T-ID.

## Fase A — Refinamiento y decisiones

- [ ] T-006 →FR-090,NFR-090. Diseñar permiso push, rutas autorizadas, bandeja sin push y eliminación con reautenticación, purga local y progreso hasta confirmación. Acepta: AC-090 tiene precondición, resultado, fuente, contraparte y evidencia esperada definidos; decisiones pertinentes D01–D08 registradas sin firmas ficticias. Depende de: fuentes y dependencias explícitas en spec; sin dependencia de construcción local.
- [ ] T-020 →FR-100,NFR-100. Desglosar el escenario propio: Definir permiso push, asociación por sesión/dispositivo, destino reautorizado, bandeja sin permiso y progreso real de eliminación con purga local. Acepta: AC-100 documenta caso positivo, negativo, fallo/reintento y responsable de cada superficie; exclusiones identificadas. Depende de: T-006.
- [ ] T-001 →FR-001,FR-002,NFR-002. Preparar Ready de una historia acotada. Acepta: requisitos y AC seleccionados, contratos pertinentes formalizados antes de consumo, decisiones bloqueantes resueltas, revisión humana identificada y plan/tareas conciliados; sin declarar Ready por lint. Depende de: T-006, T-020 y entradas de la spec; no requiere completar todo el dominio.

## Fase B — Entregable y ejecución posterior

- [ ] T-002 →FR-001,FR-002,NFR-003. Preparar el cambio del propietario con archivos reales al encargar implementación. Acepta: la historia seleccionada tiene archivos, versión, permisos y orden de cambio concretos; el estado documental no se presenta como aplicación creada. Depende de: T-001 y encargo correspondiente si hay ejecución de producto.
- [ ] T-010 →FR-001,NFR-001,NFR-003. Verificar la integración definida: Integrar avisos/bandeja/dispositivos de 022 con logout/eliminación; implementación primaria de push en 022. Acepta: AC-001, AC-002 verificados con evidencia del alcance aplicable, incluyendo rechazo/fallo y sin sustituir integración real por doble; en diseño queda procedimiento pendiente explícito. Depende de: T-002 y contrato/decisiones de esa historia.
- [ ] T-011 →FR-002,NFR-001,NFR-003. Atender el requisito propio: Cuenta solicita borrado y consulta progreso hasta confirmación de todos. Acepta: AC-002, AC-003 verificados con evidencia del alcance aplicable, incluyendo rechazo/fallo y sin sustituir integración real por doble; en diseño queda procedimiento pendiente explícito. Depende de: T-002 y contrato/decisiones de esa historia.
- [ ] T-021 →FR-100,NFR-100,NFR-003. Comprobar el escenario específico. Acepta: AC-100 — Push de cuenta anterior no revela contenido; destino cancelado no abre domicilio; sin permiso existe bandeja; trámite parcial se mantiene pendiente y no puede reaparecer cola privada borrada. Registrar resultado real o pendiente sin inventar ejecución. Depende de: T-020 y T-002; evidencia de producto solo tras implementación autorizada.
- [ ] T-003 →FR-001,FR-002,NFR-003. Integrar frontera y datos reales de la historia. Acepta: AC-001, AC-002, AC-003, AC-090, AC-100 cuentan con comprobación de consumidor/provider, almacenamiento o dispositivo según superficie; fundamentos pueden producir evidencia documental identificada sin afirmar integración. Depende de: T-010, T-011, T-021, T-212, T-213.
- [ ] T-004 →NFR-001,NFR-100. Revisar privacidad, permisos, aislamiento, errores y fallos pertinentes. Acepta: AC-001, AC-002, AC-003, AC-090, AC-100 incluyen escenarios negativos; autoridad por recurso/estado se comprueba en API y presentación/limpieza en app; ninguna PII o credencial en evidencia. Depende de: T-003.
- [ ] T-007 →FR-090,NFR-090,NFR-002. Verificar el criterio transversal de la fase. Acepta: AC-090 — Push a sesión anterior no entrega datos de nueva cuenta; borrado parcial no informa completado; cuenta bloqueada de inmediato; restaurar backup aplica supresiones antes de servir. Distinguir revisión documental de ejecución futura. Depende de: T-004; preparación del escenario ya en T-006.

## Fase C — Cierre y revisión

- [ ] T-005 →NFR-002,NFR-003. Conciliar documentos, ejecutar gates pertinentes y actualizar Memoria. Acepta: AC-001, AC-002, AC-003, AC-090, AC-100 tienen resultado/evidencia o pendiente explícito; salida/exit, entorno, limitación y revisor reales registrados; sin aprobación automática. Depende de: T-004, T-007 y checklist del incremento.

## Verificación disponible

Hoy: powershell -NoProfile -File scripts/check_sdd.ps1 desde la raíz correspondiente, más revisión de integridad de IDs y dependencias. Solo documental. Build/test/proveedores/Android no ejecutados por esta fase.

## Historias de operación — refinamiento e implementación futura

- [ ] T-212 →FR-212,NFR-001,NFR-003. Diseñar e integrar intención consumidora de EP-012; enlazar revisión de contrato, mapear resultado/error/sesión/red y cancelar respuesta obsoleta al cambiar de cuenta. Acepta: AC-212: EP-012: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Bloquear cuenta y emitir evento; no afirmar completado al recibir La UI refleja la regla del servidor, no la sustituye. Previsto en línea base; contrato formal y aceptación pendientes. Depende de: T-002 y contrato formal/decisiones de esta historia; no exige construir todo el dominio.
- [ ] T-213 →FR-213,NFR-001,NFR-003. Diseñar e integrar intención consumidora de EP-013; enlazar revisión de contrato, mapear resultado/error/sesión/red y cancelar respuesta obsoleta al cambiar de cuenta. Acepta: AC-213: EP-013: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Receipt solo permite consultar este trámite, nunca reabrir cuenta La UI refleja la regla del servidor, no la sustituye. Previsto en línea base; contrato formal y aceptación pendientes. Depende de: T-002 y contrato formal/decisiones de esta historia; no exige construir todo el dominio.
