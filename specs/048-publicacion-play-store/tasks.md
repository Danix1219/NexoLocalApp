# Tareas — 048-publicacion-play-store

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `.github/workflows/app-ci.yml`, `tools/ci/preparar_firma.py`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. El AAB solo se construye en main o release/* después de «CI · todo verde». Acepta: AC-001 comprobado por `Construir · AAB firmado`, `Seguridad · AndroidManifest y build`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. La firma falla con mensaje claro si faltan secretos o si `build.gradle.kts` no firma con `key.properties`. Acepta: AC-002 comprobado por `Construir · AAB firmado`, `Seguridad · AndroidManifest y build`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. La URL del backend de release debe ser HTTPS. Acepta: AC-003 comprobado por `Construir · AAB firmado`, `Seguridad · AndroidManifest y build`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Producción requiere aprobación de un revisor del entorno `production`. Acepta: AC-004 comprobado por `Construir · AAB firmado`, `Seguridad · AndroidManifest y build`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: reglas cubiertas por las de integración. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/resiliencia_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
