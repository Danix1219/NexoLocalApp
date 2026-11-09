# 047-CI-CD-GITHUB-TERRAFORM — CI/CD en GitHub Actions con grafo por prueba y Terraform

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-047-ci-cd-github-terraform`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [002-quality-gates](../002-quality-gates/spec.md), [014-entrega](../014-entrega/spec.md).

Fuente visual: Transversal. Actor: Equipo y responsable de entrega. Precondición: Repositorio Danix1219/NexoLocalApp con el flujo feature → develop → release → main.

Código: `src/mobile/nexo_app/` — `.github/workflows/app-ci.yml`, `.github/actions/flutter/action.yml`, `.github/workflows/infra.yml`, `tools/ci/generar_pipeline.py`, `tools/ci/compuerta.py`, `infra/github/main.tf`, `.ci/verify-sdd.ps1`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Que ningún cambio llegue a develop, release o main sin pasar cada prueba por separado, con un grafo legible y la configuración de GitHub versionada.

## 3. Alcance / Fuera de alcance

Incluye:

- Workflow `app-ci.yml` generado: preparar → calidad → unidad (1 job por archivo) → integración (1 por archivo) y seguridad (1 por archivo + herramientas) → cobertura → APK → «CI · todo verde» → AAB firmado → Play.
- Generador `tools/ci/generar_pipeline.py` y job que falla si el pipeline no está al día con las pruebas.
- Terraform `infra/github`: rulesets de main/develop/release con todos los checks requeridos, entornos firma/staging/production, variables y secretos opcionales.
- Workflow `infra.yml`: fmt y validate.
- Validador SDD acepta el `pubspec.yaml` solo con este CI real.

Fuera de alcance:

- Backend (repositorio API).
- Estado remoto de Terraform (local por ahora).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cada archivo de prueba es un job con nombre «Capa · archivo»; el grafo muestra cada uno.
- FR-002: Agregar una prueba sin regenerar el pipeline hace fallar «Pipeline · al día con las pruebas».
- FR-003: «CI · todo verde» falla si algún job terminó en falla o cancelado.
- FR-004: Terraform exige todos los checks generados en main, develop y release/*, sin force-push ni borrado y con merge commit.
- FR-005: Acciones de terceros fijadas por SHA y permisos `contents: read`.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `tools/ci/generar_pipeline.py --check`, `infra.yml (terraform validate)` |
| FR-002 | T-011 | AC-002 | `tools/ci/generar_pipeline.py --check`, `infra.yml (terraform validate)` |
| FR-003 | T-012 | AC-003 | `tools/ci/generar_pipeline.py --check`, `infra.yml (terraform validate)` |
| FR-004 | T-013 | AC-004 | `tools/ci/generar_pipeline.py --check`, `infra.yml (terraform validate)` |
| FR-005 | T-014 | AC-005 | `tools/ci/generar_pipeline.py --check`, `infra.yml (terraform validate)` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| — | `GitHub REST (proveedor integrations/github)` | — | configuración |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Un PR muestra jobs como «Unidad · models», «Integración · http-pedidos», «Seguridad · transporte» por separado.
- [ ] AC-002 → FR-002: Crear `test/unit/nuevo_test.dart` sin regenerar hace fallar el job del pipeline.
- [ ] AC-003 → FR-003: Un job de unidad en falla deja «CI · todo verde» en rojo aunque el resto pase.
- [ ] AC-004 → FR-004: `terraform plan` lista 3 rulesets con 41 checks cada uno.
- [ ] AC-005 → FR-005: `revisar_workflows.py` pasa sobre todos los workflows del repositorio.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Muchos jobs consumen minutos de Actions (repositorio público: gratis).
- El estado local de Terraform debe custodiarse.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
