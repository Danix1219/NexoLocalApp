# Tareas — 040-mensajeria-chat

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/messages/inbox_page.dart`, `lib/features/messages/chat_page.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. La bandeja muestra no leídos por conversación y el filtro «Sin leer · N». Acepta: AC-001 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. El historial llega del más nuevo al más viejo y se muestra en orden cronológico con separadores Hoy/Ayer/fecha. Acepta: AC-002 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Enviar texto o foto; el mensaje propio muestra hora y palomita de leído. Acepta: AC-003 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Bloquear pide confirmación (y avisa si hay pedido activo); bloqueada, no se puede escribir y se ofrece desbloquear. Acepta: AC-004 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Al abrir el chat se marca leído hasta el último mensaje de la contraparte. Acepta: AC-005 comprobado por `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_messages_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_mensajes_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
