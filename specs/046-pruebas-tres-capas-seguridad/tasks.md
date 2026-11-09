# Tareas — 046-pruebas-tres-capas-seguridad

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `test/support/mock_adapter.dart`, `test/support/fixtures.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Cada archivo `*_test.dart` pertenece a una sola capa por su carpeta y corre de forma independiente. Acepta: AC-001 comprobado por `test/unit`, `test/integration`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Las pruebas de integración usan respuestas con la forma de `docs/endpoints` y verifican método, ruta, cuerpo y cabeceras. Acepta: AC-002 comprobado por `test/unit`, `test/integration`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Las pruebas de seguridad fallan si aparece un secreto, una URL http no local, un `print`, un enlace externo aceptado o una subida con Bearer. Acepta: AC-003 comprobado por `test/unit`, `test/integration`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. La cobertura de la capa lógica no baja de 45 %. Acepta: AC-004 comprobado por `test/unit`, `test/integration`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
