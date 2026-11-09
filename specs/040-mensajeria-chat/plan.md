# Plan — 040-mensajeria-chat

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-040-mensajeria-chat`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/messages/inbox_page.dart
  lib/features/messages/chat_page.dart
  test/unit/fake_messages_test.dart
  test/integration/http_mensajes_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/engagement/conversations` — grupo `mensajes`: bandeja.
- GET `/v1/engagement/conversations/{id}/messages` — grupo `mensajes`: historial.
- POST `/v1/engagement/conversations/{id}/messages` — grupo `mensajes`: enviar.
- POST `/v1/engagement/conversations/{id}/read` — grupo `mensajes`: leído.
- POST `/v1/engagement/conversations/{id}/block` — grupo `mensajes`: bloquear.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/messages/inbox_page.dart` | Bandeja por rol con filtro sin leer. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/messages/chat_page.dart` | Chat con sondeo, días, sistema, fotos, respuestas rápidas y bloqueo. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Sondeo en lugar de SignalR mientras el hub no exista; misma API para cambiarlo después.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_messages_test.dart` | Unidad · fake-messages |
| FR-001 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-002 | Unidad | `test/unit/fake_messages_test.dart` | Unidad · fake-messages |
| FR-002 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-003 | Unidad | `test/unit/fake_messages_test.dart` | Unidad · fake-messages |
| FR-003 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-004 | Unidad | `test/unit/fake_messages_test.dart` | Unidad · fake-messages |
| FR-004 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| FR-005 | Unidad | `test/unit/fake_messages_test.dart` | Unidad · fake-messages |
| FR-005 | Integración | `test/integration/http_mensajes_test.dart` | Integración · http-mensajes |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-messages» · «Integración · http-mensajes» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El sondeo cada 4 s se detiene al salir del chat (Timer cancelado en dispose).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
