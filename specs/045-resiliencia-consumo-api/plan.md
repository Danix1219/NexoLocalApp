# Plan — 045-resiliencia-consumo-api

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-045-resiliencia-consumo-api`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/data/nexo_api.dart
  lib/data/api_provider.dart
  lib/data/http_nexo_api.dart
  lib/data/fake/fake_nexo_api.dart
  lib/features/shell/shell_page.dart
  lib/app/env.dart
  test/unit/api_modes_test.dart
  test/integration/resiliencia_test.dart
```

## 2. Contratos (rutas, config, env)

- * `Los 13 grupos de `docs/endpoints` excepto auth` — grupo `todos`: consumo resiliente.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/data/nexo_api.dart` | Interfaz por endpoint, borrador de prestador y `HybridNexoApi` resiliente. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/api_provider.dart` | Proveedores Riverpod, modos por grupo, ubicación, comparación y filtros. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/http_nexo_api.dart` | Llamadas reales con Bearer, Idempotency-Key, If-Match y subida en 3 pasos. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/fake/fake_nexo_api.dart` | Datos de la maqueta y simulación de la contraparte. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/shell/shell_page.dart` | Shell con barra inferior, globo de no leídos, sondeo y aviso de datos de ejemplo. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/app/env.dart` | API_BASE_URL, API_MODE, LIVE, FAKE y validación HTTPS. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Decorador `HybridNexoApi` sobre la interfaz `NexoApi`: las pantallas no saben de dónde viene el dato.
- Tiempo de conexión de 6 s para pasar rápido a ejemplo cuando el backend no contesta.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/api_modes_test.dart` | Unidad · api-modes |
| FR-001 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| FR-002 | Unidad | `test/unit/api_modes_test.dart` | Unidad · api-modes |
| FR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| FR-003 | Unidad | `test/unit/api_modes_test.dart` | Unidad · api-modes |
| FR-003 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| FR-004 | Unidad | `test/unit/api_modes_test.dart` | Unidad · api-modes |
| FR-004 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| FR-005 | Unidad | `test/unit/api_modes_test.dart` | Unidad · api-modes |
| FR-005 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · api-modes» · «Integración · resiliencia» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Mezclar datos reales y de ejemplo puede cruzar IDs (un pedido real con un prestador de ejemplo); el aviso lo hace visible.
- Escrituras en ejemplo no llegan al servidor; no sustituyen la cola offline de spec 016.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
