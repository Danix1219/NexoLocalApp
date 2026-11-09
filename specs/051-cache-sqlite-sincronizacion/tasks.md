# Tareas — 051-cache-sqlite-sincronizacion

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/core/local/local_store.dart`, `lib/core/local/sqflite_store.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Cada lectura JSON exitosa se guarda por cuenta; sin señal se responde con lo guardado y el shell muestra la hora. Acepta: AC-001 comprobado por `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Las lecturas guardadas se revalidan con `If-None-Match`; un 304 usa lo guardado. El catálogo se sirve del teléfono durante 1 h. Acepta: AC-002 comprobado por `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Publicar una solicitud sin señal la guarda en la cola con su `Idempotency-Key` y avisa que se publicará al volver la conexión; otras escrituras no se encolan. Acepta: AC-003 comprobado por `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Al reconectar, volver a la app o iniciar sesión se envía la cola de la cuenta; un rechazo de negocio se descarta y se avisa; un endpoint ausente se reintenta hasta 5 veces. Acepta: AC-004 comprobado por `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Cerrar sesión, eliminar la cuenta o una sesión invalidada borra la caché y la cola de esa cuenta; contacto, subidas, dispositivos, correo y contraseña nunca se guardan. Acepta: AC-005 comprobado por `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/almacen_local_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/cache_sin_conexion_test.dart`, `test/integration/sincronizacion_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/cache_local_seguro_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
