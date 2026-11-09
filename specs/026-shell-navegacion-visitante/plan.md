# Plan — 026-shell-navegacion-visitante

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-026-shell-navegacion-visitante`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/app/router.dart
  lib/features/shell/shell_page.dart
  lib/features/shell/gate.dart
  lib/features/shell/top_bar.dart
  lib/core/auth/session_controller.dart
  lib/features/auth/presentation/welcome_page.dart
  test/integration/sesion_test.dart
  test/security/enlaces_profundos_test.dart
  test/security/privacidad_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/engagement/conversations` — grupo `mensajes`: globo de no leídos.
- GET `/v1/engagement/notifications` — grupo `notificaciones`: punto de la campana.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/app/router.dart` | Rutas, redirecciones por sesión y lista blanca de enlaces profundos. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/shell/shell_page.dart` | Shell con barra inferior, globo de no leídos, sondeo y aviso de datos de ejemplo. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/shell/gate.dart` | Hoja y pantalla de puerta para el visitante; pantalla sin perfil de prestador. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/shell/top_bar.dart` | Barra de Inicio, chip de ubicación, campana y hoja de notificaciones. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/auth/session_controller.dart` | Estados unknown/signedOut/guest/signedIn, modo y nombre. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/auth/presentation/welcome_page.dart` | «Explorar sin cuenta» entra en modo visitante. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- StatefulShellRoute.indexedStack conserva la posición de cada pestaña.
- Estado `guest` en `SessionController` en vez de un token anónimo: el visitante nunca llama a endpoints autenticados.
- Puerta como hoja y como pantalla, igual que `gateSheet`/`gateScreen` de la maqueta.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-001 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-001 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-002 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-002 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-002 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-003 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-003 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-003 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-004 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-004 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-004 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| FR-005 | Integración | `test/integration/sesion_test.dart` | Integración · sesion |
| FR-005 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| FR-005 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| NFR-001 | Seguridad | `test/security/enlaces_profundos_test.dart` | Seguridad · enlaces-profundos |
| NFR-001 | Seguridad | `test/security/privacidad_test.dart` | Seguridad · privacidad |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Integración · sesion» · «Seguridad · enlaces-profundos» · «Seguridad · privacidad» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El visitante puede ver datos reales del feed público; la API debe filtrar campos privados (spec 007).
- El sondeo cada 30 s consume batería; se reemplaza con SignalR en spec 011.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
