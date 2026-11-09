# Tareas — 028-inicio-prestador

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/home/home_page.dart`, `lib/features/common/cards.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Sin perfil de prestador, Inicio en modo Proveedor ofrece crear el perfil (spec 044) y no llama a oportunidades. Acepta: AC-001 comprobado por `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Oportunidades lista primero pedidos por responder, luego aceptados y después solicitudes para ti ordenadas por coincidencia y urgencia. Acepta: AC-002 comprobado por `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003, AC-004. «Me interesa» envía o retira el interés y actualiza el botón; si el cliente ya eligió a otro, se muestra «Eligió a otro prestador». Acepta: AC-003, AC-004 comprobado por `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-005. Los filtros (dentro de mi radio, coincide con mi servicio, urgentes, categoría) se aplican a la consulta y muestran su conteo. Acepta: AC-005 comprobado por `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-006. Áreas de oportunidad muestra el porcentaje del perfil y el siguiente pendiente con acceso a completarlo. Acepta: AC-006 comprobado por `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_requests_test.dart`, `test/unit/filters_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_solicitudes_interes_test.dart`, `test/integration/http_pedidos_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
