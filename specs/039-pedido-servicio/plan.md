# Plan — 039-pedido-servicio

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-039-pedido-servicio`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/orders/order_page.dart
  lib/features/common/actions.dart
  lib/data/http_nexo_api.dart
  test/unit/fake_orders_test.dart
  test/integration/http_pedidos_test.dart
  test/security/privacidad_test.dart
  test/security/cabeceras_y_subidas_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/engagement/orders` — grupo `pedidos`: pedir.
- GET `/v1/engagement/orders/{id}` — grupo `pedidos`: detalle.
- POST `/v1/engagement/orders/{id}/accept|reject|cancel|resolve` — grupo `pedidos`: acciones.
- PUT `/v1/engagement/orders/{id}/address` — grupo `pedidos`: domicilio.
- POST `/v1/engagement/contacts/phone` — grupo `contacto`: copiar número.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/orders/order_page.dart` | Pedido con pasos, lugar, contraparte, acciones por rol y calificación. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/http_nexo_api.dart` | Llamadas reales con Bearer, Idempotency-Key, If-Match y subida en 3 pasos. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- La pantalla no decide permisos: muestra lo que permiten `allowedActions` y los campos que manda la API.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-001 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-001 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-002 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-002 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-002 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-003 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-003 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-003 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-004 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-004 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-004 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-005 | Unidad | `test/unit/fake_orders_test.dart` | Unidad · fake-orders |
| FR-005 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-005 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| NFR-001 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| NFR-001 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-orders» · «Integración · http-pedidos» · «Seguridad · privacidad» · «Seguridad · cabeceras-y-subidas» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- La dirección escrita no se valida con geocodificación (deuda).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
