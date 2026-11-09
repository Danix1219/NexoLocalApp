# Plan — 032-mi-perfil-edicion

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-032-mi-perfil-edicion`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/provider/edit_sheets.dart
  lib/features/provider/provider_page.dart
  lib/core/widgets/pick_image.dart
  test/unit/fake_account_test.dart
  test/integration/http_perfil_test.dart
  test/integration/http_imagenes_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/discovery/providers/me` — grupo `perfil`: perfil propio.
- PATCH `/v1/discovery/providers/me/{basic|services|zone|hours|prices|terms}` — grupo `perfil`: editar sección.
- DELETE `/v1/discovery/works/{id}` — grupo `trabajos`: borrar trabajo.
- POST `/v1/discovery/uploads` — grupo `imagenes`: foto de perfil.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/provider/edit_sheets.dart` | Hojas de edición por sección y atajos de pendientes. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/provider/provider_page.dart` | Perfil público y propio con pestañas y acciones. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/widgets/pick_image.dart` | Cámara/galería con reducción a 1600 px. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Edición por sección (PATCH pequeño) en vez de un formulario completo: menos conflictos y validación clara.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-001 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-001 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-002 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-002 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-002 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-003 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-003 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-003 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-004 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-004 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-004 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| FR-005 | Unidad | `test/unit/fake_account_test.dart` | Unidad · fake-account |
| FR-005 | Integración | `test/integration/http_perfil_test.dart` | Integración · http-perfil |
| FR-005 | Integración | `test/integration/http_imagenes_test.dart` | Integración · http-imagenes |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · fake-account» · «Integración · http-perfil» · «Integración · http-imagenes» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Los nombres de pago/respuesta del contrato son slugs; la API puede rechazar valores fuera de lista (400 con código).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
