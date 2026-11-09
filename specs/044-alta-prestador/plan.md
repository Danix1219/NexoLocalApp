# Plan — 044-alta-prestador

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-044-alta-prestador`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/onboarding/provider_onboarding_page.dart
  lib/data/nexo_api.dart
  lib/data/http_nexo_api.dart
  test/unit/fake_account_test.dart
  test/integration/http_perfil_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/discovery/providers` — grupo `perfil`: crear perfil.
- POST `/v1/identity/me/mode` — grupo `cuenta`: cambiar a Proveedor.
- POST `/v1/discovery/uploads` — grupo `imagenes`: foto.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/onboarding/provider_onboarding_page.dart` | Alta de prestador en 5 pasos. | FR-001, FR-002, FR-003, FR-004 |
| `lib/data/nexo_api.dart` | Interfaz por endpoint, borrador de prestador y `HybridNexoApi` resiliente. | FR-001, FR-002, FR-003, FR-004 |
| `lib/data/http_nexo_api.dart` | Llamadas reales con Bearer, Idempotency-Key, If-Match y subida en 3 pasos. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Horario, precios y condiciones fuera del alta para reducir abandono; se completan desde «Completa tu perfil».

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-001 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-002 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-002 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-003 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-003 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-004 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-004 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-account» · «Integración · http-perfil» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Si `/me/mode` aún no existe, el modo se guarda localmente (spec 041).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
