# Plan — 033-comparar-prestadores

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-033-comparar-prestadores`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/provider/compare_page.dart
  lib/features/common/cards.dart
  lib/data/api_provider.dart
  test/unit/fake_discovery_test.dart
  test/integration/http_perfil_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/providers/compare?ids=a,b` — grupo `perfil`: filas de comparación.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/provider/compare_page.dart` | Tabla comparativa con el mejor resaltado. | FR-001, FR-002, FR-003 |
| `lib/features/common/cards.dart` | Tarjetas de trabajo, solicitud, pedido, prestador y barra de comparar. | FR-001, FR-002, FR-003 |
| `lib/data/api_provider.dart` | Proveedores Riverpod, modos por grupo, ubicación, comparación y filtros. | FR-001, FR-002, FR-003 |

Decisiones de diseño:

- La selección vive en memoria; se limpia al cerrar sesión o cambiar de modo.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-001 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-002 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-002 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-003 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-003 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-discovery» · «Integración · http-perfil» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Si la API no envía `best`, no se resalta nada (no se calcula en el cliente para no contradecir al servidor).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
