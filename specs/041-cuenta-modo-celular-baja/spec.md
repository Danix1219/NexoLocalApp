# 041-CUENTA-MODO-CELULAR-BAJA — Cuenta: modo cliente/prestador, celular, privacidad, salir y eliminar

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-041-cuenta-modo-celular-baja`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [017-cuenta-recuperacion-sesiones](../017-cuenta-recuperacion-sesiones/spec.md), [012-notificaciones-borrado](../012-notificaciones-borrado/spec.md), [004-identidad-sesion](../004-identidad-sesion/spec.md).

Fuente visual: 7.13 Cuenta (`V.account`, `roleBlock`, `delSheet`, `logoutSheet`). Actor: Persona con sesión o visitante. Precondición: Sesión o modo visitante.

Código: `src/mobile/nexo_app/` — `lib/features/account/account_page.dart`, `lib/features/account/phone_sheet.dart`, `lib/core/auth/session_controller.dart`, `lib/core/auth/token_storage.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Administrar la cuenta en un solo lugar y cambiar entre cliente y prestador con la misma cuenta.

## 3. Alcance / Fuera de alcance

Incluye:

- Tarjeta propia (nombre, foto, celular confirmado, zona) y edición de nombre/foto.
- Modo de uso Cliente/Proveedor con `POST /me/mode` (tokens nuevos) o guardado local mientras la API no exista.
- Cliente: intereses, ubicación, actividad. Prestador: zona, completitud, disponibilidad, contacto, visibilidad.
- Celular: alta y código de 6 dígitos.
- Privacidad, términos, cerrar sesión y eliminar con contraseña (30 días para arrepentirse) y cancelar eliminación.
- Cuenta del visitante con beneficios y botones de alta.

Fuera de alcance:

- Sesiones/dispositivos (spec 017 posterior).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cambiar a Proveedor sin perfil lleva al alta (spec 044); con perfil cambia el modo, limpia la comparación y refresca la actividad.
- FR-002: Si la API devuelve tokens con el claim nuevo se usan; si no, el modo se guarda en el teléfono y sobrevive a la renovación del token.
- FR-003: Confirmar celular: 10 dígitos con prefijo +52, luego código de 6; el número se muestra enmascarado.
- FR-004: Cerrar sesión llama al logout, borra tokens, nombre y modo del teléfono aunque el servidor no responda.
- FR-005: Eliminar exige contraseña; la cuenta queda en eliminación pendiente con opción de cancelar.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/fake_account_test.dart`, `test/integration/http_cuenta_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/privacidad_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/screens/account` | cuenta | pantalla compuesta |
| PATCH | `/v1/identity/me` | cuenta | nombre y foto |
| POST | `/v1/identity/me/mode` | cuenta | modo |
| POST | `/v1/identity/me/phone` | cuenta | celular |
| POST | `/v1/identity/me/phone/confirm` | cuenta | código |
| POST/DELETE | `/v1/identity/me/deletion` | cuenta | eliminar o cancelar |
| POST | `/v1/identity/logout` | auth | cerrar sesión |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Cuenta sin perfil que toca «Proveedor» abre el registro de prestador.
- [ ] AC-002 → FR-002: Tras cambiar a Proveedor sin tokens, una renovación conserva el modo Proveedor.
- [ ] AC-003 → FR-003: Código «12» muestra el error; «123456» confirma y aparece «Celular confirmado».
- [ ] AC-004 → FR-004: Tras cerrar sesión el almacenamiento seguro queda vacío y se ve Bienvenida.
- [ ] AC-005 → FR-005: Con eliminación pendiente aparece el aviso con «Cancelar eliminación».

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El modo guardado localmente es una ayuda de transición; el servidor sigue autorizando por token (constitución §2).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
