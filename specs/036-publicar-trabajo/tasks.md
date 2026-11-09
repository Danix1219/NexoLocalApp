# Tareas — 036-publicar-trabajo

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/publish/publish_page.dart`, `lib/data/http_nexo_api.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. «Publicar» se habilita con 20+ caracteres e indica cuántos faltan. Acepta: AC-001 comprobado por `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Las fotos se reducen a 1600 px y se suben antes de crear el trabajo; el trabajo lleva los `uploadId`. Acepta: AC-002 comprobado por `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. La subida a la URL firmada nunca lleva el Bearer de Nexo. Acepta: AC-003 comprobado por `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. El trabajo se envía con la ubicación del perfil y aparece en Mi perfil. Acepta: AC-004 comprobado por `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: reglas cubiertas por las de integración. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_imagenes_test.dart`, `test/integration/http_solicitudes_interes_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/cabeceras_y_subidas_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
