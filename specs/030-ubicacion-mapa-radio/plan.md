# Plan — 030-ubicacion-mapa-radio

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-030-ubicacion-mapa-radio`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/location/location_picker_page.dart
  lib/core/widgets/map_view.dart
  lib/features/shell/top_bar.dart
  lib/data/api_provider.dart
  test/unit/fake_discovery_test.dart
  test/integration/http_descubrimiento_test.dart
```

## 2. Contratos (rutas, config, env)

- PUT `/v1/discovery/me/location` — grupo `descubrimiento`: guardar ubicación de búsqueda.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/location/location_picker_page.dart` | Selector de punto y radio con GPS opcional. | FR-001, FR-002, FR-003, FR-004 |
| `lib/core/widgets/map_view.dart` | Mini mapa, mapa con puntos y alfiler (flutter_map + ArcGIS). | FR-001, FR-002, FR-003, FR-004 |
| `lib/features/shell/top_bar.dart` | Barra de Inicio, chip de ubicación, campana y hoja de notificaciones. | FR-001, FR-002, FR-003, FR-004 |
| `lib/data/api_provider.dart` | Proveedores Riverpod, modos por grupo, ubicación, comparación y filtros. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Alfiler fijo y mapa móvil (como la maqueta) evita arrastrar marcadores pequeños.
- flutter_map 7 + latlong2 con mosaicos de la maqueta; sin llave de API.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-001 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-002 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-002 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-003 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-003 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-004 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-004 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-discovery» · «Integración · http-descubrimiento» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El GPS en interiores puede tardar; hay límite de 15 s.
- Mosaicos ArcGIS requieren internet; sin señal el mapa queda gris pero la app no falla.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
