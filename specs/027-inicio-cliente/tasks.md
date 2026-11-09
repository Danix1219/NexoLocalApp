# Tareas — 027-inicio-cliente

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/home/home_page.dart`, `lib/features/common/cards.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Para ti lista los trabajos del feed de la zona activa; primero los de categorías de interés o de solicitudes abiertas. Acepta: AC-001 comprobado por `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002, AC-003. Cada publicación permite recomendar (optimista con reversión), compartir, comparar al prestador, guardar y contactar. Acepta: AC-002, AC-003 comprobado por `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-004. Mis solicitudes muestra Mis servicios (pedidos no cancelados ni rechazados) y cada solicitud con el pie de su estado: con pedido, con interesados, sin interesados o resuelta. Acepta: AC-004 comprobado por `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-005. Con interesados, el pie muestra hasta 4 avatares, «+N» y lleva a Interesados; también permite cerrar la solicitud. Acepta: AC-005 comprobado por `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-006. Sin solicitudes, se ofrece «Publicar lo que necesito». Acepta: AC-006 comprobado por `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_discovery_test.dart`, `test/unit/models_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_descubrimiento_test.dart`, `test/integration/http_solicitudes_interes_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
