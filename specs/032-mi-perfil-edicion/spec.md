# 032-MI-PERFIL-EDICION — Mi perfil de prestador: completitud y edición por sección

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-032-mi-perfil-edicion`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [006-perfiles](../006-perfiles/spec.md), [018-catalogo-seleccion](../018-catalogo-seleccion/spec.md).

Fuente visual: «Completa tu perfil» (`todoCard`) y hojas de edición de horario, precios y condiciones. Actor: Prestador dueño del perfil. Precondición: Perfil creado (spec 044).

Código: `src/mobile/nexo_app/` — `lib/features/provider/edit_sheets.dart`, `lib/features/provider/provider_page.dart`, `lib/core/widgets/pick_image.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Completar y mantener el perfil por secciones pequeñas, viendo cuánto falta y qué aporta cada pendiente.

## 3. Alcance / Fuera de alcance

Incluye:

- Tarjeta de completitud con pendientes y puntos.
- Hojas: básico (foto, nombre, acerca de), servicios (≤3 categorías y especialidades), zona, horario (7 días, urgencias), precios (visita y ≤3 servicios) y condiciones (pago, respuesta, garantía, factura, llamadas).
- Borrar trabajos propios con confirmación.

Fuera de alcance:

- Portafolio editable y portada (deuda).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: Cada pendiente de la tarjeta abre la hoja que lo resuelve; al guardar se recalcula el porcentaje.
- FR-002: Horario guarda 7 días con `open`/`close` HH:mm o null y la bandera de urgencias.
- FR-003: Precios guarda la visita (no mostrar, sin costo, con costo) y hasta 3 servicios en centavos o «a cotizar».
- FR-004: Condiciones guarda pagos (cash, transfer, card), tiempo de respuesta (sameDay, h24, h48, week), garantía, factura y si muestra el número.
- FR-005: Servicios limita a 3 categorías; quitar una categoría quita sus especialidades.

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
| FR-005 | T-014 | AC-005 | `test/unit/fake_account_test.dart`, `test/integration/http_perfil_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/providers/me` | perfil | perfil propio |
| PATCH | `/v1/discovery/providers/me/{basic|services|zone|hours|prices|terms}` | perfil | editar sección |
| DELETE | `/v1/discovery/works/{id}` | trabajos | borrar trabajo |
| POST | `/v1/discovery/uploads` | imagenes | foto de perfil |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Guardar el horario marca «Horario de atención» como hecho y sube el porcentaje.
- [ ] AC-002 → FR-002: Abrir solo lunes 9–18 envía `days[0]={open:'09:00',close:'18:00'}` y el resto null.
- [ ] AC-003 → FR-003: Un servicio «a cotizar» se envía con `fromCents=null` y `unit=quote`.
- [ ] AC-004 → FR-004: Quitar Tarjeta y elegir 48 h envía `payment` sin `card` y `responseTime=h48`.
- [ ] AC-005 → FR-005: Con 3 categorías elegidas, una cuarta muestra «Máximo 3 categorías».

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- Los nombres de pago/respuesta del contrato son slugs; la API puede rechazar valores fuera de lista (400 con código).
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |

## Incremento 2026-11-25 · editor de horario

- FR-HOURS-001: Cada día tiene interruptor y un botón con su rango; no se usan menús desplegables flotantes.
- FR-HOURS-002: El rango se elige en un panel inferior con cuadrícula de horas (apertura 5–22, cierre posterior a la apertura y hasta 23) y puede copiarse a todos los días activos.
- FR-HOURS-003: Atajos «Lun a vie», «Lun a sáb» y «Todos los días»; urgencias como interruptor; resumen de días abiertos.
- FR-HOURS-004: Se envía el mismo `schedule` (`days` de 7 posiciones en `HH:00` o `null`, y `urgent`). Si el servidor falla, el editor sigue abierto con los cambios.
- AC-HOURS: elegir rango, copiarlo y guardar produce los 7 días esperados (`diseno_maqueta_test.dart`).

## 2026-11-26 · edición desde la foto y código QR
- FR-EDIT-001: En Mi perfil del solicitante no hay botón «Editar datos de mi perfil». Al abrir la foto de perfil, el botón de edición abre «Editar perfil» con foto y nombre.
- FR-PHOTO-INSTANT: portada y foto propias se precargan y se conservan; mientras no se conoce la portada se ve un fondo neutro, no el decorativo. Al cambiar una foto, la vista local permanece hasta que la nueva está lista.
- FR-QR-UI: tarjeta con cabecera de marca, foto, nombre, QR enmarcado, compartir y copiar. El QR conserva corrección Q, margen de 4 módulos y sin logo encima.

## 2026-11-26 · hojas «¿Cuánto cobras?» y «Condiciones»
Se afinan las hojas existentes; no cambian los datos que se envían.
- FR-PRICE-UI-001: Cada servicio (nombre, precio o «A cotizar») forma una fila dentro de un mismo contorno, con contador «n de 3» y opción de quitarla. El signo de pesos se ve siempre. La visita explica cómo quedará en el perfil.
- FR-PRICE-UI-002: Los errores aparecen junto al campo y la hoja se desplaza al primero. Una fila con precio o «A cotizar» pero sin nombre pide el nombre; ya no se descarta sin avisar.
- FR-TERMS-UI-001: Formas de pago en casillas de ancho fijo con ícono y marca. Factura (solo negocio) y llamadas son interruptores que dicen qué verá el cliente.
- FR-TERMS-UI-002: El tiempo de respuesta es opcional: sin dato guardado no se preselecciona ninguno (se envía `responseTime: null`) y tocar la opción elegida la quita.
