# 031-PERFIL-PRESTADOR — Perfil público del prestador: Trabajos, Información y Opiniones

Versión: 0.5.0 | Fecha: 2026-11-08 | Rama prevista: `feature/<CLAVE-JIRA>-031-perfil-prestador`

## 1. Contexto

Constitución rectora: [fuente única](../../constitution.md). Specs de dominio que esta pantalla/función integra: [006-perfiles](../006-perfiles/spec.md), [020-experiencias-reputacion](../020-experiencias-reputacion/spec.md), [025-contacto-consentimiento](../025-contacto-consentimiento/spec.md).

Fuente visual: 7.8 Perfil (`V.profile`, `infoHTML`, `trustPanel`). Actor: Cliente, visitante o el propio prestador. Precondición: Id de prestador válido.

Código: `src/mobile/nexo_app/` — `lib/features/provider/provider_page.dart`, `lib/features/common/actions.dart`, `lib/data/models.dart`.

Esta spec describe el recorrido pantalla → estado (Riverpod) → `NexoApi` → API o datos de ejemplo. El servidor autoriza y modera; la app refleja sus respuestas.

## 2. Objetivo

Mostrar quién es el prestador, qué hace, cuándo atiende, cuánto cobra de referencia, dónde atiende y qué opinan, con acciones para contactar, guardar, pedir o llegar al local.

## 3. Alcance / Fuera de alcance

Incluye:

- Portada, avatar, insignias (teléfono confirmado, nuevo, sin actualizar) y datos rápidos.
- Estadísticas: trabajos, recomiendan y radio o distancia del local.
- Acciones: Contactar, Guardar, Compartir, Pedir este servicio, Cómo llegar.
- Pestañas Trabajos (cuadrícula y lista), Información (disponibilidad, giro, acerca de, precios, condiciones, zona) y Opiniones.
- Reportar perfil.

Fuera de alcance:

- Edición del perfil propio (spec 032).

## 4. Requisitos (FR-xxx / NFR-xxx trazables a test y código)

- FR-001: El encabezado muestra nombre, tipo (negocio u oficio), categorías, insignias con su significado y datos rápidos (atención, estado, visita, precio desde).
- FR-002: Información muestra el horario de la semana con el día de hoy resaltado, precios con «Desde»/«A cotizar», condiciones y la zona en mapa; lo no publicado dice «No publicó».
- FR-003: Opiniones muestra el resumen (recomiendan de total) y cada opinión; sin opiniones en perfil nuevo aclara que no es negativo.
- FR-004: Con local, «Cómo llegar» abre la app de mapas en la ubicación del local.
- FR-005: El perfil propio muestra «Mi perfil», «Completa tu perfil» y botones de edición por sección en lugar de Contactar.

- NFR-001: Seguridad y privacidad: sin secretos ni datos personales en registros; Bearer solo hacia Nexo; datos privados (teléfono, dirección) solo cuando la API los entrega; enlaces y entradas validados (spec 046, constitución §6, H01/H02).
- NFR-002: Resiliencia: si un endpoint de esta spec no existe o no hay señal, la pantalla funciona con datos de ejemplo y sin error; los errores de negocio sí se muestran (spec 045).
- NFR-003: Estados y accesibilidad: carga, vacío, error recuperable y reintento; etiquetas semánticas en botones de ícono; objetivos táctiles de 44 px o más; texto legible en español.
- NFR-004: Verificación: pruebas por capa en `test/unit`, `test/integration` y `test/security`, cada archivo como job del pipeline, y «CI · todo verde» antes de fusionar (specs 046 y 047).

### Matriz requisito → tarea → criterio → prueba

| ID | Tarea | Criterio | Prueba (capa · archivo) |
|---|---|---|---|
| FR-001 | T-010 | AC-001 | `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-002 | T-011 | AC-002 | `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-003 | T-012 | AC-003 | `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-004 | T-013 | AC-004 | `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart` |
| FR-005 | T-014 | AC-005 | `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart` |
| NFR-001 | T-004 | AC-901 | `test/security` (transversal) |
| NFR-002 | T-003 | AC-902 | `test/integration/resiliencia_test.dart` |
| NFR-003 | T-005 | AC-903 | Revisión en dispositivo (T-005) |
| NFR-004 | T-002 | AC-904 | Pipeline `app-ci.yml` |

## 5. Contratos (rutas, config, env)

Autoridad de contratos: API Nexo (`docs/endpoints`). Consumo en la app: [endpoints-ui](../../docs/endpoints-ui.md). Mapa de pantallas y pruebas: [pantallas y pruebas](../../docs/pantallas-y-pruebas.md).

| Método | Ruta | Grupo (`LIVE`/`FAKE`) | Uso |
|---|---|---|---|
| GET | `/v1/discovery/providers/{id}` | perfil | perfil |
| GET | `/v1/discovery/providers/{id}/works` | trabajos | trabajos |
| GET | `/v1/engagement/providers/{id}/reviews` | opiniones | opiniones |

Configuración: `API_BASE_URL` (HTTPS en release), `API_MODE` (`auto` por omisión), `LIVE` y `FAKE` por grupo ([spec 045](../045-resiliencia-consumo-api/spec.md)). Sin secretos en código.

## 6. Criterios de aceptación verificables

- [ ] AC-001 → FR-001: Perfil con `phoneVerified` muestra «Teléfono confirmado» y al tocar abre «Cómo leer las señales».
- [ ] AC-002 → FR-002: Prestador sin precios muestra «No publicó» en precios, sin inventar valores.
- [ ] AC-003 → FR-003: Perfil con `isNew` sin opiniones muestra «Perfil nuevo, aún sin historial».
- [ ] AC-004 → FR-004: Tocar «Cómo llegar» lanza la URL de Google Maps con el destino del local.
- [ ] AC-005 → FR-005: Abrir `/provider/me` con perfil propio no muestra Contactar ni Reportar.

- [ ] AC-901 → NFR-001: Los jobs de seguridad pertinentes pasan y ninguna pantalla de esta spec muestra o guarda un dato privado que la respuesta no incluya.
- [ ] AC-902 → NFR-002: Con el backend apagado la pantalla carga en modo auto sin mensaje de error y con el aviso de datos de ejemplo; un error con código de Nexo se muestra.
- [ ] AC-903 → NFR-003: Revisión en Android: cada estado tiene mensaje y acción; TalkBack lee los botones de ícono.
- [ ] AC-904 → NFR-004: Los jobs listados en el plan aparecen y pasan en el PR; la evidencia queda en el checklist.

## 7. Riesgos y deudas documentadas

- El portafolio editable queda pendiente; se muestran las fotos que mande la API.
- La evidencia de producto (jobs en verde y revisión en Android) aún no se ha ejecutado; ningún criterio está aceptado.

## Aprobación y Control de Cambios

Estado: Borrador documental; código implementado en `src/mobile/nexo_app`, evidencia de CI y de dispositivo pendiente de la primera ejecución.
Revisores: por asignar.
Fecha de revisión: pendiente.
Detalle: spec por pantalla/función derivada de la maqueta V1.00.002 aprobada y del código entregado; refina, no reemplaza, las specs de dominio enlazadas.

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 0.5.0 | 2026-11-08 | Asistente, sin firma humana | Spec, plan, tareas y checklist por pantalla/función con matriz de trazabilidad |
