# 048-PUBLICACION-PLAY-STORE — Firma y publicación en Google Play

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-048-publicacion-play-store`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [014-entrega](../014-entrega/spec.md), [024-landing-evaluacion](../024-landing-evaluacion/spec.md).

Fuente visual: Transversal. Actor: Responsable de entrega. Precondición: Cuenta de Google Play Console, app creada con el paquete `mx.nexolocal.nexo_app` y primera subida manual hecha.

Código: `src/mobile/nexo_app/` — `.github/workflows/app-ci.yml`, `tools/ci/preparar_firma.py`, `docs/play-store.md`, `infra/github/main.tf`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Construir un AAB firmado y subirlo a pruebas internas desde `release/*` y a producción desde `main` con aprobación humana.

## 3. Alcance / Fuera de alcance

Incluye:

- Llave de subida en el entorno `firma` (base64) y `key.properties` generado en el runner y borrado al final.
- AAB con `--obfuscate --split-debug-info`, número de compilación por ejecución y URL HTTPS validada.
- Pista `internal` desde release/*; `production` desde main con revisores.
- Estado `draft` mientras la app no esté publicada.

Fuera de alcance:

- Ficha de la tienda, capturas y política de privacidad pública (spec 024).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: El AAB solo se construye en main o release/* después de «CI · todo verde».
- FR-002: La firma falla con mensaje claro si faltan secretos o si `build.gradle.kts` no firma con `key.properties`.
- FR-003: La URL del backend de release debe ser HTTPS.
- FR-004: Producción requiere aprobación de un revisor del entorno `production`.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `Construir · AAB firmado`, `Seguridad · AndroidManifest y build` |
| FR-002 | T-011 | AC-002 | `Construir · AAB firmado`, `Seguridad · AndroidManifest y build` |
| FR-003 | T-012 | AC-003 | `Construir · AAB firmado`, `Seguridad · AndroidManifest y build` |
| FR-004 | T-013 | AC-004 | `Construir · AAB firmado`, `Seguridad · AndroidManifest y build` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| — | `Google Play Developer API (acción upload-google-play)` | — | subida |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Un push a feature/* no ejecuta «Construir · AAB firmado».
- [ ] AC-002 → FR-002: Sin `ANDROID_KEYSTORE_BASE64` el job muestra «Faltan secretos de firma…» y no construye.
- [ ] AC-003 → FR-003: Con `API_BASE_URL=http://…` el job falla antes de compilar.
- [ ] AC-004 → FR-004: Un push a main queda en espera de aprobación antes de subir a producción.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Perder la llave de subida obliga a pedir reinicio en Play Console; guardar respaldo fuera del repositorio.
- La primera versión debe subirse a mano en Play Console (la API no crea apps).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
