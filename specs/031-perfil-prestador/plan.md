# Plan — 031-perfil-prestador

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-031-perfil-prestador`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/provider/provider_page.dart
  lib/features/common/actions.dart
  lib/data/models.dart
  test/unit/models_test.dart
  test/integration/http_perfil_test.dart
  test/integration/http_pedidos_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/providers/{id}` — grupo `perfil`: perfil.
- GET `/v1/discovery/providers/{id}/works` — grupo `trabajos`: trabajos.
- GET `/v1/engagement/providers/{id}/reviews` — grupo `opiniones`: opiniones.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/provider/provider_page.dart` | Perfil público y propio con pestañas y acciones. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/common/actions.dart` | Acciones compartidas: contactar, reportar, guardar, comparar, pedir, interés y cierre. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/data/models.dart` | Modelos con los nombres de campo de los contratos y valores seguros por omisión. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- La pestaña Información replica `infoHTML`: tarjetas por tema en lugar de una tabla larga.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-001 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-001 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-002 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-002 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-002 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-003 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-003 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-003 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-004 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-004 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-004 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| FR-005 | Unidad | `test/unit/models_test.dart` | Unidad · models |
| FR-005 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-005 | Integración | `test/integration/http_pedidos_test.dart` | Integración · http-pedidos |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · models» · «Integración · http-perfil» · «Integración · http-pedidos» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El portafolio editable queda pendiente; se muestran las fotos que mande la API.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
