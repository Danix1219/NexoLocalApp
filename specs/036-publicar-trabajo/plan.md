# Plan — 036-publicar-trabajo

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-036-publicar-trabajo`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/publish/publish_page.dart
  lib/data/http_nexo_api.dart
  lib/core/widgets/pick_image.dart
  test/integration/http_imagenes_test.dart
  test/integration/http_solicitudes_interes_test.dart
  test/security/cabeceras_y_subidas_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/discovery/works` — grupo `trabajos`: publicar.
- POST `/v1/discovery/uploads` — grupo `imagenes`: ticket.
- PUT `{uploadUrl}` — grupo `imagenes`: subida directa.
- POST `/v1/discovery/uploads/{id}/complete` — grupo `imagenes`: confirmar.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/publish/publish_page.dart` | Compositores de solicitud, experiencia y trabajo; título automático. | FR-001, FR-002, FR-003, FR-004 |
| `lib/data/http_nexo_api.dart` | Llamadas reales con Bearer, Idempotency-Key, If-Match y subida en 3 pasos. | FR-001, FR-002, FR-003, FR-004 |
| `lib/core/widgets/pick_image.dart` | Cámara/galería con reducción a 1600 px. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Cliente Dio separado para la subida directa (sin interceptores).

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-001 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-001 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-002 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-002 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-002 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-003 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-003 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-003 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-004 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-004 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-004 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| NFR-001 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Integración · http-imagenes» · «Integración · http-solicitudes-interes» · «Seguridad · cabeceras-y-subidas» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Si la URL firmada vence durante una subida lenta, se reporta error y se puede reintentar.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
