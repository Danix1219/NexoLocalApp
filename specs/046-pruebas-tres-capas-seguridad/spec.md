# 046-PRUEBAS-TRES-CAPAS-SEGURIDAD — Pruebas en tres capas: unidad, integración y seguridad

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-046-pruebas-tres-capas-seguridad`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [002-quality-gates](../002-quality-gates/spec.md), [023-privacidad-permisos-enlaces](../023-privacidad-permisos-enlaces/spec.md).

Fuente visual: Transversal. Actor: Equipo de desarrollo y revisor. Precondición: Flutter 3.29 / Dart 3.7.

Código: `src/mobile/nexo_app/` — `test/support/mock_adapter.dart`, `test/support/fixtures.dart`, `test/support/fake_api.dart`, `tools/ci/cobertura.py`, `tools/ci/revisar_android.py`, `tools/ci/revisar_workflows.py`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Que cada capacidad tenga pruebas automáticas separadas por capa, ejecutables por archivo, y controles de seguridad que bloqueen el merge.

## 3. Alcance / Fuera de alcance

Incluye:

- `test/unit`: reglas, modelos, filtros, modos y API de ejemplo por dominio.
- `test/integration`: HttpNexoApi contra un adaptador Dio por grupo (rutas, métodos, cuerpos, cabeceras), resiliencia y sesión con el interceptor.
- `test/security`: secretos en código, transporte HTTPS, enlaces profundos, registros sin datos sensibles, Idempotency-Key/If-Match/Bearer, privacidad H01/H02 y aislamiento por cuenta.
- Herramientas: gitleaks, OSV sobre pubspec.lock, revisión de AndroidManifest/gradle, actionlint y SHA fijados, revisión de dependencias del PR.
- Cobertura combinada con umbral de 45 % sobre la capa lógica.

Fuera de alcance:

- Pruebas en dispositivo (integration_test) — deuda.
- Pruebas de widgets con fuentes reales.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cada archivo `*_test.dart` pertenece a una sola capa por su carpeta y corre de forma independiente.
- FR-002: Las pruebas de integración usan respuestas con la forma de `docs/endpoints` y verifican método, ruta, cuerpo y cabeceras.
- FR-003: Las pruebas de seguridad fallan si aparece un secreto, una URL http no local, un `print`, un enlace externo aceptado o una subida con Bearer.
- FR-004: La cobertura de la capa lógica no baja de 45 %.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit`, `test/integration` |
| FR-002 | T-011 | AC-002 | `test/unit`, `test/integration` |
| FR-003 | T-012 | AC-003 | `test/unit`, `test/integration` |
| FR-004 | T-013 | AC-004 | `test/unit`, `test/integration` |
| NFR-001 | T-004 | AC-901 | `test/security` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| — | `Sin endpoints propios; prueba los de 026–045` | — | — |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: `flutter test test/unit/models_test.dart` corre solo ese archivo y pasa sin red.
- [ ] AC-002 → FR-002: Cambiar la ruta de `acceptOrder` hace fallar `Integración · http-pedidos`.
- [ ] AC-003 → FR-003: Agregar `const k = 'AIza…'` en `lib/` hace fallar `Seguridad · secretos-en-codigo`.
- [ ] AC-004 → FR-004: Con 40 % en la capa lógica el job `Calidad · cobertura combinada` falla.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Las pruebas de integración usan dobles HTTP; no sustituyen pruebas contra el backend desplegado (constitución §7).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
