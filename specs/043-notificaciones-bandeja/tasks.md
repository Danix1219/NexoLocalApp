# Tareas — 043-notificaciones-bandeja

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/shell/top_bar.dart`, `lib/app/router.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. La campana muestra un punto si hay no leídas. Acepta: AC-001 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Tocar un aviso con `deepLink` válido navega a la sección; uno inválido se ignora. Acepta: AC-002 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Al cerrar la hoja se marcan leídas las mostradas. Acepta: AC-003 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_guardados_contacto_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_account_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_guardados_contacto_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/enlaces_profundos_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
