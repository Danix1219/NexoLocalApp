# Tareas — 035-publicar-solicitud

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/publish/publish_page.dart`, `lib/core/widgets/pick_image.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. «Publicar» se habilita con servicio elegido y 10+ caracteres. Acepta: AC-001 comprobado por `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. El título se genera de la primera frase; si es menor a 5 caracteres usa el texto completo. Acepta: AC-002 comprobado por `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. La solicitud se envía con urgencia y contacto como slugs del contrato y la ubicación elegida o la de búsqueda. Acepta: AC-003 comprobado por `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Repetir «Publicar» por red lenta no duplica: la clave de idempotencia es la misma hasta publicar con éxito. Acepta: AC-004 comprobado por `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/publish_rules_test.dart`, `test/unit/fake_requests_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_solicitudes_interes_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
