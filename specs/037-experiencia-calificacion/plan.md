# Plan — 037-experiencia-calificacion

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-037-experiencia-calificacion`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/publish/publish_page.dart
  lib/features/orders/order_page.dart
  test/unit/fake_orders_test.dart
  test/integration/http_pedidos_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/engagement/reviews` — grupo `opiniones`: calificar.
- GET `/v1/engagement/orders?role=client` — grupo `pedidos`: pedidos resueltos.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/publish/publish_page.dart` | Compositores de solicitud, experiencia y trabajo; título automático. | FR-001, FR-002, FR-003 |
| `lib/features/orders/order_page.dart` | Pedido con pasos, lugar, contraparte, acciones por rol y calificación. | FR-001, FR-002, FR-003 |

Decisiones de diseño:

- Recomendación por omisión: sí con 4–5 estrellas, no con menos (editable).

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-001 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-002 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-002 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-003 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-003 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-orders» · «Integración · http-pedidos» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Moderación del texto en API (spec 005).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
