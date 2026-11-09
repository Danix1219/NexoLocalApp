# Tareas — 050-notificaciones-push

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/push/push_controller.dart`, `lib/features/push/push_gateway.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Después de entrar, si el proveedor está disponible y no hay permiso, se muestra una vez «¿Te avisamos?» con «Activar avisos» y «Ahora no». Acepta: AC-001 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Con permiso se registra el teléfono con `fcmToken`, `platform` y `appVersion`, y se guarda solo el `deviceId`; al rotar el token se vuelve a registrar. Acepta: AC-002 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Con la app abierta, un aviso refresca bandeja, pedidos y solicitudes y muestra su título. Acepta: AC-003 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Tocar un aviso abre la pantalla de su `deepLink` solo si es `nexolocal://` hacia una sección conocida. Acepta: AC-004 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Apagar avisos o cerrar sesión da de baja el teléfono en el backend y borra el token local. Acepta: AC-005 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.
- [ ] T-015 →FR-006; AC-006. Sin Firebase configurado la app funciona igual y no hace llamadas de dispositivos. Acepta: AC-006 comprobado por `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/push_mensajes_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014, T-015.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/push_controlador_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/push_seguro_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
