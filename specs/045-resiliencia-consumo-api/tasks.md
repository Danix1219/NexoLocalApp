# Tareas — 045-resiliencia-consumo-api

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/data/nexo_api.dart`, `lib/data/api_provider.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001, AC-002. En modo `auto`, una llamada «no disponible» responde con los datos de ejemplo del mismo método, sin error en pantalla. Acepta: AC-001, AC-002 comprobado por `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-003. Un error de negocio con código de Nexo nunca se reemplaza por datos de ejemplo. Acepta: AC-003 comprobado por `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-004. Tras 60 s se vuelve a intentar el backend; si responde, el grupo regresa a datos reales y el aviso desaparece. Acepta: AC-004 comprobado por `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-005. Sin señal, todos los grupos en `auto` pasan a ejemplo a la vez para no esperar el tiempo de conexión en cada pantalla. Acepta: AC-005 comprobado por `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-006. `LIVE` fuerza grupos al backend (sus errores se muestran) y `FAKE` los fuerza a la maqueta sin red. Acepta: AC-006 comprobado por `test/unit/api_modes_test.dart`, `test/integration/resiliencia_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/api_modes_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/resiliencia_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
