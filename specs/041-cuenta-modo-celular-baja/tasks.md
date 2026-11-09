# Tareas — 041-cuenta-modo-celular-baja

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/account/account_page.dart`, `lib/features/account/phone_sheet.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Cambiar a Proveedor sin perfil lleva al alta (spec 044); con perfil cambia el modo, limpia la comparación y refresca la actividad. Acepta: AC-001 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Si la API devuelve tokens con el claim nuevo se usan; si no, el modo se guarda en el teléfono y sobrevive a la renovación del token. Acepta: AC-002 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Confirmar celular: 10 dígitos con prefijo +52, luego código de 6; el número se muestra enmascarado. Acepta: AC-003 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Cerrar sesión llama al logout, borra tokens, nombre y modo del teléfono aunque el servidor no responda. Acepta: AC-004 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Eliminar exige contraseña; la cuenta queda en eliminación pendiente con opción de cancelar. Acepta: AC-005 comprobado por `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_account_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_cuenta_test.dart`, `test/integration/sesion_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/privacidad_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
