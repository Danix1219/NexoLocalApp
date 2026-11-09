# Plan — 027-inicio-cliente

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-027-inicio-cliente`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/home/home_page.dart
  lib/features/common/cards.dart
  lib/features/common/carousel.dart
  lib/features/common/actions.dart
  test/unit/fake_discovery_test.dart
  test/unit/models_test.dart
  test/integration/http_descubrimiento_test.dart
  test/integration/http_solicitudes_interes_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/feed` — grupo `descubrimiento`: trabajos cercanos.
- GET `/v1/discovery/requests/mine` — grupo `solicitudes`: mis solicitudes.
- GET `/v1/engagement/orders?role=client` — grupo `pedidos`: mis servicios.
- POST/DELETE `/v1/discovery/works/{id}/recommend` — grupo `trabajos`: recomendar.
- POST/DELETE `/v1/discovery/saved/work/{id}` — grupo `guardados`: guardar trabajo.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/home/home_page.dart` | Inicio de cliente y de prestador con pestañas y refresco. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/cards.dart` | Tarjetas de trabajo, solicitud, pedido, prestador y barra de comparar. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/carousel.dart` | Carrusel de fotos con contador, puntos y flechas. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Recomendar es optimista con reversión, como la maqueta.
- Intereses locales (sin endpoint) sólo reordenan, no filtran.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-001 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-001 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-002 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-002 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-002 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-003 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-003 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-003 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-004 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-004 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-004 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| FR-005 | Unidad | `test/unit/fake_discovery_test.dart` | Unidad · fake-discovery |
| FR-005 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-005 | Integración | `test/integration/http_descubrimiento_test.dart` | Integración · http-descubrimiento |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-discovery» · «Unidad · models» · «Integración · http-descubrimiento» · «Integración · http-solicitudes-interes» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El feed real puede no traer `recommended`/`saved` por usuario si el contrato cambia; los modelos usan falso por omisión.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
