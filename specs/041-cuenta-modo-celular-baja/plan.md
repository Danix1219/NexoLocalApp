# Plan — 041-cuenta-modo-celular-baja

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-041-cuenta-modo-celular-baja`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/account/account_page.dart
  lib/features/account/phone_sheet.dart
  lib/core/auth/session_controller.dart
  lib/core/auth/token_storage.dart
  test/unit/fake_account_test.dart
  test/integration/http_cuenta_test.dart
  test/integration/sesion_test.dart
  test/security/privacidad_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/screens/account` — grupo `cuenta`: pantalla compuesta.
- PATCH `/v1/identity/me` — grupo `cuenta`: nombre y foto.
- POST `/v1/identity/me/mode` — grupo `cuenta`: modo.
- POST `/v1/identity/me/phone` — grupo `cuenta`: celular.
- POST `/v1/identity/me/phone/confirm` — grupo `cuenta`: código.
- POST/DELETE `/v1/identity/me/deletion` — grupo `cuenta`: eliminar o cancelar.
- POST `/v1/identity/logout` — grupo `auth`: cerrar sesión.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/account/account_page.dart` | Cuenta de cliente, prestador y visitante; modo, salir y eliminar. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/account/phone_sheet.dart` | Alta y confirmación de celular. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/auth/session_controller.dart` | Estados unknown/signedOut/guest/signedIn, modo y nombre. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/auth/token_storage.dart` | Tokens, nombre y modo en almacenamiento seguro; limpieza al salir. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- `setMode` con o sin tokens en `SessionController`; al iniciar otra cuenta se borra el modo local.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-001 | Integración | `test/integration/http_cuenta_test.dart` | Integración · http-cuenta |
| FR-001 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-002 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-002 | Integración | `test/integration/http_cuenta_test.dart` | Integración · http-cuenta |
| FR-002 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-003 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-003 | Integración | `test/integration/http_cuenta_test.dart` | Integración · http-cuenta |
| FR-003 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-004 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-004 | Integración | `test/integration/http_cuenta_test.dart` | Integración · http-cuenta |
| FR-004 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-005 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-005 | Integración | `test/integration/http_cuenta_test.dart` | Integración · http-cuenta |
| FR-005 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| NFR-001 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-account» · «Integración · http-cuenta» · «Integración · sesion» · «Seguridad · privacidad» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El modo guardado localmente es una ayuda de transición; el servidor sigue autorizando por token (constitución §2).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.


## Incremento de ubicacion/perfil 2026-11-09

Registro y selector GPS/mapa: register_account_page.dart, location_picker_page.dart, auth_repository.dart. Persistencia: api_provider.dart y PUT /v1/discovery/me/location en backend. Mi perfil y edicion separada: account_page.dart. Proximamente: ui.dart, solo rutas sin implementacion. Fotos pendientes de Blob/moderacion confirmados por usuario. Evidencia de pruebas en docs/integracion-identity-cuenta.md; ninguna firma ni aceptacion humana agregada.
