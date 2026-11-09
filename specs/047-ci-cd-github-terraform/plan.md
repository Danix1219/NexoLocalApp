# Plan — 047-ci-cd-github-terraform

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-047-ci-cd-github-terraform`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
../../../.github/workflows/app-ci.yml
../../../.github/actions/flutter/action.yml
../../../.github/workflows/infra.yml
../../../tools/ci/generar_pipeline.py
../../../tools/ci/compuerta.py
../../../infra/github/main.tf
../../../.ci/verify-sdd.ps1
```

## 2. Contratos (rutas, config, env)

- — `GitHub REST (proveedor integrations/github)` — grupo `—`: configuración.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `.github/workflows/app-ci.yml` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `.github/actions/flutter/action.yml` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `.github/workflows/infra.yml` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `tools/ci/generar_pipeline.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `tools/ci/compuerta.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `infra/github/main.tf` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `.ci/verify-sdd.ps1` | Ver spec. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Un job por archivo en lugar de matriz para que cada prueba sea un check requerible por nombre.
- YAML generado por script para que pipeline y protección de ramas no se desalineen.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Pipeline | `tools/ci/generar_pipeline.py --check` | tools/ci/generar_pipeline.py --check |
| FR-001 | Pipeline | `infra.yml (terraform validate)` | infra.yml (terraform validate) |
| FR-002 | Pipeline | `tools/ci/generar_pipeline.py --check` | tools/ci/generar_pipeline.py --check |
| FR-002 | Pipeline | `infra.yml (terraform validate)` | infra.yml (terraform validate) |
| FR-003 | Pipeline | `tools/ci/generar_pipeline.py --check` | tools/ci/generar_pipeline.py --check |
| FR-003 | Pipeline | `infra.yml (terraform validate)` | infra.yml (terraform validate) |
| FR-004 | Pipeline | `tools/ci/generar_pipeline.py --check` | tools/ci/generar_pipeline.py --check |
| FR-004 | Pipeline | `infra.yml (terraform validate)` | infra.yml (terraform validate) |
| FR-005 | Pipeline | `tools/ci/generar_pipeline.py --check` | tools/ci/generar_pipeline.py --check |
| FR-005 | Pipeline | `infra.yml (terraform validate)` | infra.yml (terraform validate) |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «tools/ci/generar_pipeline.py --check» · «infra.yml (terraform validate)» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Muchos jobs consumen minutos de Actions (repositorio público: gratis).
- El estado local de Terraform debe custodiarse.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
