# Plan — 034-contacto-reportes-senales

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-034-contacto-reportes-senales`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/common/actions.dart
  lib/features/common/cards.dart
  test/integration/http_guardados_contacto_test.dart
  test/integration/http_mensajes_test.dart
  test/security/cabeceras_y_subidas_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/engagement/conversations` — grupo `mensajes`: iniciar chat.
- POST `/v1/engagement/contacts/phone` — grupo `contacto`: ver número.
- POST `/v1/engagement/reports` — grupo `contacto`: reportar.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003, FR-004 |
| `lib/features/common/cards.dart` | Tarjetas de trabajo, solicitud, pedido, prestador y barra de comparar. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Chat primero, número después (privacidad H01).

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-001 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-001 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-002 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-002 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-002 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-003 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-003 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-003 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| FR-004 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-004 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-004 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| NFR-001 | Seguridad | `test/security/cabeceras_y_subidas_test.dart` | Seguridad · cabeceras-y-subidas |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Integración · http-guardados-contacto» · «Integración · http-mensajes» · «Seguridad · cabeceras-y-subidas» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Revelar el número genera evento de contacto en la API; el cliente no lo cachea.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
