# 026-SHELL-NAVEGACION-VISITANTE — Barra inferior, navegación y modo visitante

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-026-shell-navegacion-visitante`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [001-base-flutter](../001-base-flutter/spec.md), [004-identidad-sesion](../004-identidad-sesion/spec.md), [023-privacidad-permisos-enlaces](../023-privacidad-permisos-enlaces/spec.md).

Fuente visual: 7.1 Bienvenida, 7.14 Explorar sin cuenta y barra `.navbar` de la maqueta V1.00.002. Actor: Persona sin cuenta (visitante), cliente o prestador con sesión. Precondición: App instalada; sesión restaurada desde almacenamiento seguro o ausente.

Código: `src/mobile/nexo_app/` — `lib/app/router.dart`, `lib/features/shell/shell_page.dart`, `lib/features/shell/gate.dart`, `lib/features/shell/top_bar.dart`, `lib/core/auth/session_controller.dart`, `lib/features/auth/presentation/welcome_page.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Navegar entre Inicio, Buscar, Publicar, Mensajes y Cuenta con el mismo shell para ambos modos, permitir explorar sin cuenta y pedir cuenta solo al intentar una acción privada.

## 3. Alcance / Fuera de alcance

Incluye:

- Shell con 5 pestañas y pila independiente por pestaña (StatefulShellRoute).
- Globo de no leídos en Mensajes y punto de avisos en la campana.
- Modo visitante: Inicio con 2 trabajos, Buscar completo, pantallas de puerta para Publicar, Mensajes y Cuenta.
- Hoja de puerta (`gateSheet`) al contactar, guardar, comparar o recomendar sin cuenta.
- Redirecciones del router por estado de sesión (unknown, signedOut, guest, signedIn).
- Aviso discreto cuando algún grupo usa datos de ejemplo (spec 045).

Fuera de alcance:

- Login, registro y recuperación (spec 004).
- Push del sistema operativo (spec 022).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: La barra inferior muestra Inicio, Buscar, Publicar, Mensajes y Cuenta con la pestaña activa resaltada y altura propia (no ocupa la pantalla).
- FR-002: Sin sesión, «Explorar sin cuenta» abre Inicio en modo visitante; el router permite Inicio y Buscar y muestra puerta en Publicar, Mensajes y Cuenta.
- FR-003: Toda acción privada (contactar, guardar, comparar, recomendar, avisos) abre la hoja de puerta con «Crear cuenta gratis» e «Iniciar sesión»; al elegir, el visitante sale del modo y llega al flujo de spec 004.
- FR-004: El globo de Mensajes refleja `totalUnread` del rol activo y se refresca cada 30 s y al volver de un chat.
- FR-005: Las redirecciones respetan la sesión: con sesión no se ve el flujo de entrada; sin sesión ni visitante no se ve el shell.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart` |
| FR-002 | T-011 | AC-002, AC-003 | `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart` |
| FR-003 | T-012 | AC-004 | `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart` |
| FR-004 | T-013 | AC-005 | `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart` |
| FR-005 | T-014 | AC-006 | `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/enlaces_profundos_test.dart`, `test/security/privacidad_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/engagement/conversations` | mensajes | globo de no leídos |
| GET | `/v1/engagement/notifications` | notificaciones | punto de la campana |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: La barra mide lo de sus botones (≈70 px) y el contenido de la pestaña ocupa el resto; cada botón tiene objetivo táctil ≥ 48 px y etiqueta de accesibilidad.
- [ ] AC-002 → FR-002: Visitante ve 2 trabajos y la tarjeta «Esto es solo una probadita»; no ve conteos de su actividad.
- [ ] AC-003 → FR-002: Visitante en Publicar, Mensajes o Cuenta ve la pantalla de puerta, sin llamadas autenticadas.
- [ ] AC-004 → FR-003: Visitante que toca Contactar, Guardar, Comparar o Recomendar ve la hoja de puerta; no se envía ninguna petición.
- [ ] AC-005 → FR-004: Con 3 no leídos el globo muestra 3; al leer el chat baja a 0 tras volver.
- [ ] AC-006 → FR-005: Con sesión, abrir `/login` lleva a `/home`; sin sesión, abrir `/home` lleva a `/`.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El visitante puede ver datos reales del feed público; la API debe filtrar campos privados (spec 007).
- El sondeo cada 30 s consume batería; se reemplaza con SignalR en spec 011.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
