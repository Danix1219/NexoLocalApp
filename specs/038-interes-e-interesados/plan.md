# Plan — 038-interes-e-interesados

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-038-interes-e-interesados`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/requests/interested_page.dart
  lib/features/common/actions.dart
  test/unit/fake_requests_test.dart
  test/integration/http_solicitudes_interes_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/engagement/requests/{id}/interested?sort=` — grupo `interes`: interesados.
- POST `/v1/discovery/requests/{id}/close` — grupo `solicitudes`: cerrar.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/requests/interested_page.dart` | Interesados ordenables con mensaje, comparar y pedir. | FR-001, FR-002, FR-003 |
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003 |

Decisiones de diseño:

- Comparar desde interesados reutiliza la barra global (spec 033).

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-001 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-002 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-002 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-003 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-003 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-requests» · «Integración · http-solicitudes-interes» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Orden y permisos son del servidor; el cliente no reordena localmente.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
