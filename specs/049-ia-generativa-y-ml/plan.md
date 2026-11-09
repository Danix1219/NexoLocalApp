# Plan — 049-ia-generativa-y-ml

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-049-ia-generativa-y-ml`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/intelligence/category_suggester.dart
  lib/features/intelligence/ml_kit_suggester.dart
  lib/features/intelligence/assist_sheet.dart
  lib/features/intelligence/redact.dart
  lib/features/publish/publish_page.dart
  lib/data/http_nexo_api.dart
  lib/data/nexo_api.dart
  lib/data/fake/fake_nexo_api.dart
  test/unit/ml_categoria_test.dart
  test/integration/http_asistente_dispositivos_test.dart
  test/unit/asistente_y_dispositivos_fake_test.dart
  test/security/ia_sin_datos_personales_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/assist/draft` — grupo `asistente`: borrador generativo editable (EP-082, por formalizar).
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/intelligence/category_suggester.dart` | Decisión de categoría por etiquetas con abstención (ML). | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/intelligence/ml_kit_suggester.dart` | Modelo de visión en el teléfono (ML Kit Image Labeling). | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/intelligence/assist_sheet.dart` | Botón y hoja del borrador generativo editable; aviso de sugerencia por foto. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/intelligence/redact.dart` | Quita teléfono, correo, enlaces y domicilio antes de la IA. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/publish/publish_page.dart` | Compositores de solicitud, experiencia y trabajo; título automático. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/data/http_nexo_api.dart` | Llamadas reales con Bearer, Idempotency-Key, If-Match y subida en 3 pasos. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/data/nexo_api.dart` | Interfaz por endpoint, borrador de prestador y `HybridNexoApi` resiliente. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/data/fake/fake_nexo_api.dart` | Datos de la maqueta y simulación de la contraparte. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |

Decisiones de diseño:

- ML en el teléfono: la foto no sale del dispositivo para sugerir la categoría.
- IA generativa en el backend: la app no guarda llaves de proveedores de IA.
- La maqueta solo genera plantillas marcadas «sin IA» en depuración o `API_MODE=fake`.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-001 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-001 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| FR-002 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-002 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-002 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| FR-003 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-003 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-003 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| FR-004 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-004 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-004 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| FR-005 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-005 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-005 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| FR-006 | Unidad | `test/unit/ml_categoria_test.dart` | Unidad · ml-categoria |
| FR-006 | Integración | `test/integration/http_asistente_dispositivos_test.dart` | Integración · http-asistente-dispositivos |
| FR-006 | Unidad | `test/unit/asistente_y_dispositivos_fake_test.dart` | Unidad · asistente-y-dispositivos-fake |
| NFR-001 | Seguridad | `test/security/ia_sin_datos_personales_test.dart` | Seguridad · ia-sin-datos-personales |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · ml-categoria» · «Integración · http-asistente-dispositivos» · «Unidad · asistente-y-dispositivos-fake» · «Seguridad · ia-sin-datos-personales» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- El modelo base de ML Kit no está entrenado con fotos de servicios de Nexo: falta medir macro-F1, abstención y latencia con un conjunto de evaluación propio (spec 013, AC-001/AC-090).
- EP-082 sigue «por formalizar» en el inventario de la API; si el backend cambia la forma, se ajusta `assistDraft`.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-015 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
