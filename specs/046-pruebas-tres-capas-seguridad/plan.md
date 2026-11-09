# Plan — 046-pruebas-tres-capas-seguridad

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-046-pruebas-tres-capas-seguridad`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  test/support/mock_adapter.dart
  test/support/fixtures.dart
  test/support/fake_api.dart
../../../tools/ci/cobertura.py
../../../tools/ci/revisar_android.py
../../../tools/ci/revisar_workflows.py
  test/unit
  test/integration
  test/security
```

## 2. Contratos (rutas, config, env)

- — `Sin endpoints propios; prueba los de 026–045` — grupo `—`: —.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `test/support/mock_adapter.dart` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `test/support/fixtures.dart` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `test/support/fake_api.dart` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `tools/ci/cobertura.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `tools/ci/revisar_android.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `tools/ci/revisar_workflows.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Dobles en el borde HTTP (adaptador Dio) para probar el código real de serialización y cabeceras.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Unidad | `test/unit` | Unidad · (todos los archivos de la carpeta) |
| FR-001 | Integración | `test/integration` | Integración · (todos los archivos de la carpeta) |
| FR-001 | Seguridad | `test/security` | Seguridad · (todos los archivos de la carpeta) |
| FR-002 | Unidad | `test/unit` | Unidad · (todos los archivos de la carpeta) |
| FR-002 | Integración | `test/integration` | Integración · (todos los archivos de la carpeta) |
| FR-002 | Seguridad | `test/security` | Seguridad · (todos los archivos de la carpeta) |
| FR-003 | Unidad | `test/unit` | Unidad · (todos los archivos de la carpeta) |
| FR-003 | Integración | `test/integration` | Integración · (todos los archivos de la carpeta) |
| FR-003 | Seguridad | `test/security` | Seguridad · (todos los archivos de la carpeta) |
| FR-004 | Unidad | `test/unit` | Unidad · (todos los archivos de la carpeta) |
| FR-004 | Integración | `test/integration` | Integración · (todos los archivos de la carpeta) |
| FR-004 | Seguridad | `test/security` | Seguridad · (todos los archivos de la carpeta) |
| NFR-001 | Seguridad | `test/security` | Seguridad · (todos los archivos de la carpeta) |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Unidad · (todos los archivos de la carpeta)» · «Integración · (todos los archivos de la carpeta)» · «Seguridad · (todos los archivos de la carpeta)» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Las pruebas de integración usan dobles HTTP; no sustituyen pruebas contra el backend desplegado (constitución §7).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
