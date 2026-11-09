# Plan — 052-privacidad-landing-produccion

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-052-privacidad-landing-produccion`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/auth/presentation/legal_sheets.dart
  lib/features/account/account_page.dart
  lib/app/env.dart
  lib/core/widgets/ui.dart
../../../tools/android/preparar_android.py
../../../tools/ci/versionamiento.py
../../../tools/ci/preparar_firebase.py
../../../docs/versionamiento.md
  test/security/transporte_test.dart
  test/security/secretos_en_codigo_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/identity/me/deletion` — grupo `cuenta`: solicitar baja (spec 041).
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/auth/presentation/legal_sheets.dart` | Aviso y términos con enlace a la landing. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/account/account_page.dart` | Cuenta de cliente, prestador y visitante; modo, salir y eliminar. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/app/env.dart` | API_BASE_URL (producción HTTPS), API_MODE, LIVE, FAKE, LANDING_URL, APP_VERSION y validación HTTPS. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/core/widgets/ui.dart` | Mensajes de error (moderación, cola) y componentes. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `tools/android/preparar_android.py` | Ajusta manifiesto y gradle para producción. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `tools/ci/versionamiento.py` | Comprueba la matriz de versiones. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `tools/ci/preparar_firebase.py` | Escribe google-services.json desde secretos. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `docs/versionamiento.md` | Matriz de versionamiento. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |

Decisiones de diseño:

- Las páginas legales viven en la landing (requisito 17) y la app las enlaza.
- El AAB falla en vez de publicar sin push o sin aviso de privacidad.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-001 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-001 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| FR-002 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-002 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-002 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| FR-003 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-003 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-003 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| FR-004 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-004 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-004 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| FR-005 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-005 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-005 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| FR-006 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| FR-006 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| FR-006 | Pipeline | `Versión · matriz y SemVer` | Versión · matriz y SemVer |
| NFR-001 | Seguridad | `test/security/transporte_test.dart` | Seguridad · transporte |
| NFR-001 | Seguridad | `test/security/secretos_en_codigo_test.dart` | Seguridad · secretos-en-codigo |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Seguridad · transporte» · «Seguridad · secretos-en-codigo» · «Versión · matriz y SemVer» · «Seguridad · AndroidManifest y build» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- La landing debe publicar las tres páginas antes del AAB de producción.
- El texto legal dentro de la app es un resumen; el vigente es el de la landing.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-015 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
