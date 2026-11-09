# 050-NOTIFICACIONES-PUSH — Notificaciones push de los procesos principales

Versión: 0.6.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-050-notificaciones-push`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [022-push-dispositivos](../022-push-dispositivos/spec.md), [012-notificaciones-borrado](../012-notificaciones-borrado/spec.md), [043-notificaciones-bandeja](../043-notificaciones-bandeja/spec.md).

Fuente visual: Permiso de notificaciones (pantalla previa propia) y bandeja de avisos; requisito 16: «Notificaciones Push para el o los procesos principales». Actor: Cliente o prestador con sesión. Precondición: Build con `google-services.json` (Firebase); sin él la app funciona sin push.

Código: `src/mobile/nexo_app/` — `lib/features/push/push_controller.dart`, `lib/features/push/push_gateway.dart`, `lib/features/push/firebase_push_gateway.dart`, `lib/features/shell/shell_page.dart`, `lib/features/account/account_page.dart`, `lib/core/auth/token_storage.dart`, `lib/app/app.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Avisar en el teléfono cuando alguien se interesa en una solicitud, aceptan o resuelven un pedido o llega un mensaje, y abrir la pantalla correcta al tocar el aviso.

## 3. Alcance / Fuera de alcance

Incluye:

- Pantalla previa «¿Te avisamos?» una vez por sesión y opción en Cuenta para activar o apagar.
- Registro del token FCM con `POST /v1/identity/devices` (`platform: android`, `appVersion`) al conceder permiso, al iniciar sesión y cuando Firebase rota el token.
- Aviso con la app abierta: refresca la actividad y muestra el texto.
- Tocar el aviso abre su `deepLink` validado; si la sesión aún no se restauró, se abre al entrar.
- Baja con `DELETE /v1/identity/devices/{id}` y borrado del token al apagar avisos o cerrar sesión.

Fuera de alcance:

- Envío de los avisos (worker del backend con FirebaseAdmin).
- Avisos por correo o SMS.

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Después de entrar, si el proveedor está disponible y no hay permiso, se muestra una vez «¿Te avisamos?» con «Activar avisos» y «Ahora no».
- FR-002: Con permiso se registra el teléfono con `fcmToken`, `platform` y `appVersion`, y se guarda solo el `deviceId`; al rotar el token se vuelve a registrar.
- FR-003: Con la app abierta, un aviso refresca bandeja, pedidos y solicitudes y muestra su título.
- FR-004: Tocar un aviso abre la pantalla de su `deepLink` solo si es `nexolocal://` hacia una sección conocida.
- FR-005: Apagar avisos o cerrar sesión da de baja el teléfono en el backend y borra el token local.
- FR-006: Sin Firebase configurado la app funciona igual y no hace llamadas de dispositivos.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| FR-004 | T-013 | AC-004 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| FR-005 | T-014 | AC-005 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| FR-006 | T-015 | AC-006 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/push_seguro_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/identity/devices` | dispositivos | registrar teléfono |
| DELETE | `/v1/identity/devices/{id}` | dispositivos | dar de baja |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: `shouldAsk` es verdadero la primera vez y falso después de mostrarla.
- [ ] AC-002 → FR-002: `POST /v1/identity/devices` con `fcmToken=tok-abc` y `platform=android`; el almacenamiento guarda `dev_1`, no el token.
- [ ] AC-003 → FR-003: Un aviso en primer plano incrementa el evento de actividad con su título.
- [ ] AC-004 → FR-004: `nexolocal://orders/ord_1` abre `/orders/ord_1`; `https://…`, `nexolocal://admin/1` y rutas con `..` no abren nada.
- [ ] AC-005 → FR-005: `DELETE /v1/identity/devices/dev_1` y token borrado; el estado queda apagado.
- [ ] AC-006 → FR-006: Con el proveedor sin configurar, `enable` devuelve falso y no hay llamadas HTTP.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Requiere proyecto de Firebase y su `google-services.json` como secreto del entorno `firma`.
- El contenido del aviso lo define el backend: no debe llevar domicilio ni teléfono (contrato de notificaciones).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.6.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
