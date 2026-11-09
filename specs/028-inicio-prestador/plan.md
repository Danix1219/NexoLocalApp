# Plan — 028-inicio-prestador

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-028-inicio-prestador`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/home/home_page.dart
  lib/features/common/cards.dart
  lib/features/search/filters.dart
  lib/features/common/actions.dart
  test/unit/fake_requests_test.dart
  test/unit/filters_test.dart
  test/integration/http_solicitudes_interes_test.dart
  test/integration/http_pedidos_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/requests/opportunities` — grupo `solicitudes`: solicitudes para ti.
- GET `/v1/engagement/orders?role=provider` — grupo `pedidos`: pendientes y aceptados.
- GET `/v1/discovery/providers/me` — grupo `perfil`: perfil propio y completitud.
- POST/DELETE `/v1/engagement/requests/{id}/interest` — grupo `interes`: me interesa.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/home/home_page.dart` | Inicio de cliente y de prestador con pestañas y refresco. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/cards.dart` | Tarjetas de trabajo, solicitud, pedido, prestador y barra de comparar. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/search/filters.dart` | Botón y hojas de filtros del cliente y del prestador. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Filtros compartidos entre Inicio y Buscar del prestador para que el conteo coincida.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-001 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-001 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-002 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-002 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-002 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-003 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-003 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-003 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-004 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-004 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-004 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| FR-005 | Unidad | `test/unit/fake_requests_test.dart` | Unidad · fake-requests |
| FR-005 | Unidad | `test/unit/filters_test.dart` | Unidad · filters |
| FR-005 | Integración | `test/integration/http_solicitudes_interes_test.dart` | Integración · http-solicitudes-interes |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-requests» · «Unidad · filters» · «Integración · http-solicitudes-interes» · «Integración · http-pedidos» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- `pickedProvider` se compara con el id del perfil propio; si la API cambia el identificador, «Te eligió» no se muestra.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
