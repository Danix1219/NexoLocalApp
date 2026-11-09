# 044-ALTA-PRESTADOR — Registro de prestador: tipo, datos, servicios, zona y listo

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-044-alta-prestador`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [006-perfiles](../006-perfiles/spec.md), [018-catalogo-seleccion](../018-catalogo-seleccion/spec.md).

Fuente visual: Registro del prestador (`OBSTEPS.pro`, `obStep`, `obDone`). Actor: Persona con sesión que ofrece servicios. Precondición: Sesión; sin perfil de prestador.

Código: `src/mobile/nexo_app/` — `lib/features/onboarding/provider_onboarding_page.dart`, `lib/data/nexo_api.dart`, `lib/data/http_nexo_api.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Crear el perfil profesional en 5 pasos cortos y quedar en modo Proveedor, dejando horario y precios para después.

## 3. Alcance / Fuera de alcance

Incluye:

- Tipo: oficio o negocio.
- Datos: foto opcional, nombre o nombre comercial, responsable (negocio), atención (negocio), experiencia, equipo, acerca de (20–600).
- Servicios: rubro y actividad (negocio), hasta 3 categorías y 5 especialidades.
- Zona: mapa con radio 2/5/10/20 km o local.
- Listo: resumen y compromiso; crear con `Idempotency-Key` y cambiar a Proveedor.

Fuera de alcance:

- Verificación de identidad o documentos.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cada paso solo continúa con sus datos válidos; volver no pierde lo capturado.
- FR-002: El alta envía los campos del contrato: `crew` (alone, withHelpers, team), `trades` para oficio, `owner` y `sector` solo para negocio, `radiusKm` 0 si atiende en local.
- FR-003: Al terminar cambia a modo Proveedor y ofrece completar horario y precios.
- FR-004: Salir a la mitad pide confirmación.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_account_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_account_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_account_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_account_test.dart`, `test/integration/http_perfil_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/discovery/providers` | perfil | crear perfil |
| POST | `/v1/identity/me/mode` | cuenta | cambiar a Proveedor |
| POST | `/v1/discovery/uploads` | imagenes | foto |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Acerca de con 15 caracteres deja «Continuar» deshabilitado.
- [ ] AC-002 → FR-002: Oficio de plomería envía `trades=['Plomero/a']` y no envía `owner`.
- [ ] AC-003 → FR-003: Tras publicar, Inicio muestra Oportunidades y el pedido de ejemplo en modo de prueba.
- [ ] AC-004 → FR-004: La flecha atrás en el paso 1 pregunta «¿Salir sin terminar?».

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Si `/me/mode` aún no existe, el modo se guarda localmente (spec 041).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
