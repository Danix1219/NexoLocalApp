# Plan — 029-buscar-prestadores

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-029-buscar-prestadores`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/search/search_page.dart
  lib/features/search/filters.dart
  lib/core/widgets/map_view.dart
  lib/data/models.dart
  test/unit/fake_discovery_test.dart
  test/unit/filters_test.dart
  test/integration/http_descubrimiento_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/search/providers` — grupo `descubrimiento`: resultados.
- GET `/v1/discovery/search/suggest` — grupo `descubrimiento`: sugerencias.
- GET `/v1/discovery/map/nearby?kind=providers` — grupo `descubrimiento`: mapa.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/search/search_page.dart` | Buscar con sugerencias, chips, aros de categoría, lista y mapa. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/search/filters.dart` | Botón y hojas de filtros del cliente y del prestador. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/widgets/map_view.dart` | Mini mapa, mapa con puntos y alfiler (flutter_map + ArcGIS). | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/models.dart` | Modelos con los nombres de campo de los contratos y valores seguros por omisión. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Debounce de 280 ms para no saturar la API mientras se escribe.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-001 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-001 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-002 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-002 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-002 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-003 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-003 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-003 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-004 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-004 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-004 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-005 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-005 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-005 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-discovery» · «Unidad · filters» · «Integración · http-descubrimiento» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Las sugerencias dependen de `/search/suggest`; mientras no exista, el modo auto usa el catálogo local.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
