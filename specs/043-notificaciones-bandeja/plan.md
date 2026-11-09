# Plan — 043-notificaciones-bandeja

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-043-notificaciones-bandeja`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/shell/top_bar.dart
  lib/app/router.dart
  test/unit/fake_account_test.dart
  test/integration/http_guardados_contacto_test.dart
  test/security/enlaces_profundos_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/engagement/notifications` — grupo `notificaciones`: lista.
- POST `/v1/engagement/notifications/read` — grupo `notificaciones`: marcar leídas.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/shell/top_bar.dart` | Barra de Inicio, chip de ubicación, campana y hoja de notificaciones. | FR-001, FR-002, FR-003 |
| `lib/app/router.dart` | Rutas, redirecciones por sesión y lista blanca de enlaces profundos. | FR-001, FR-002, FR-003 |

Decisiones de diseño:

- Lista blanca de secciones en `Routes.fromDeepLink`.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-001 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-001 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-002 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-002 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-002 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-003 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-003 | Integración | `test/integration/http_guardados_contacto_test.dart` | Integración · http-guardados-contacto |
| FR-003 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| NFR-001 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-account» · «Integración · http-guardados-contacto» · «Seguridad · enlaces-profundos» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Sin push, el aviso se ve al abrir la app o en el sondeo de 30 s.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
