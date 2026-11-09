# 034-CONTACTO-REPORTES-SENALES — Contactar, ver número, reportar y señales de confianza

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-034-contacto-reportes-senales`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [025-contacto-consentimiento](../025-contacto-consentimiento/spec.md), [005-contenido-seguro](../005-contenido-seguro/spec.md), [023-privacidad-permisos-enlaces](../023-privacidad-permisos-enlaces/spec.md).

Fuente visual: `contactSheet`, `reportSheet`, `trustSheet` y `workSheet` de la maqueta. Actor: Cliente con sesión. Precondición: Prestador, trabajo, solicitud o conversación visibles.

Código: `src/mobile/nexo_app/` — `lib/features/common/actions.dart`, `lib/features/common/cards.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Iniciar el contacto por chat como vía principal, revelar el número solo si el prestador lo permite y reportar contenido con motivo.

## 3. Alcance / Fuera de alcance

Incluye:

- Hoja de contacto con «Iniciar chat», tiempo de respuesta y número oculto con «Ver número»/«Copiar».
- Hoja de reporte con 6 categorías y motivo de 10 a 300 caracteres.
- Hoja de señales (declarado, teléfono confirmado, recomendaciones, perfil nuevo).
- Detalle de trabajo en hoja con carrusel.

Fuera de alcance:

- Llamada directa desde la app (se copia el número).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: «Iniciar chat» abre (o reutiliza) la conversación con el prestador y navega al chat.
- FR-002: El número solo se pide al tocar «Ver número» y solo si el prestador tiene llamadas activas; se puede copiar.
- FR-003: Reportar exige categoría y motivo de al menos 10 caracteres y envía `Idempotency-Key`.
- FR-004: Las insignias abren la explicación de qué certifica cada una.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/integration/http_guardados_contacto_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-002 | T-011 | AC-002 | `test/integration/http_guardados_contacto_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-003 | T-012 | AC-003 | `test/integration/http_guardados_contacto_test.dart`, `test/integration/http_mensajes_test.dart` |
| FR-004 | T-013 | AC-004 | `test/integration/http_guardados_contacto_test.dart`, `test/integration/http_mensajes_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security/cabeceras_y_subidas_test.dart` |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| POST | `/v1/engagement/conversations` | mensajes | iniciar chat |
| POST | `/v1/engagement/contacts/phone` | contacto | ver número |
| POST | `/v1/engagement/reports` | contacto | reportar |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Dos toques en «Iniciar chat» con el mismo prestador abren la misma conversación.
- [ ] AC-002 → FR-002: Prestador con `channels.call=false` no muestra la sección «¿Prefieres llamar?».
- [ ] AC-003 → FR-003: Motivo de 5 caracteres deja «Enviar reporte» deshabilitado.
- [ ] AC-004 → FR-004: «Teléfono confirmado» explica que no certifica capacidad técnica.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Revelar el número genera evento de contacto en la API; el cliente no lo cachea.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
