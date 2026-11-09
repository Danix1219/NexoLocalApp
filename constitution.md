# Constitución — App_NexoLocal

Versión: 0.6.0 (enmienda 2026-11-08: requisitos de producción del profesor; 0.5.0 misma fecha: fase de implementación). Estado: Borrador; pendiente de ratificación técnica y de revisor humano. Fuente de verdad: `constitution.md`.

## 1. Propósito y alcance

App Flutter que consume las APIs de Nexo. Una spec describe un recorrido de pantalla→ViewModel→repositorio→API/SQLite; no acceso directo a bases del backend.

## 2. Principios

Fuentes vigentes: requisitos académicos, maqueta aprobada y hallazgos H01-H12. Seguridad, aislamiento por usuario, datos mínimos, fallos explícitos y evidencia verificable. Spec antes de cambio observable. Nunca inferir autorización de los alias Tú/me ni del modo de pantalla. No copiar los defectos de la maqueta como reglas permitidas.

## 3. Stack

Flutter confirmado por usuario. Implementación en `src/mobile/nexo_app` (v0.5.0): Flutter 3.29.x / Dart 3.7, Riverpod 3 (solo `Notifier`/`FutureProvider`), go_router 16 con `StatefulShellRoute`, Dio 5, flutter_secure_storage para credenciales, flutter_map + latlong2 para el mapa, geolocator, image_picker, url_launcher, sqflite + connectivity_plus (caché y cola local), firebase_core + firebase_messaging (push) y google_mlkit_image_labeling (ML en el teléfono). Las versiones exactas las fija `pubspec.lock`, que se versiona; Dependabot propone actualizaciones hacia develop. Almacenamiento local SQLite por cuenta implementado para caché de lecturas y cola de publicar solicitud (spec 051); el resto de la spec 016 sigue pendiente.

Una dependencia nueva requiere spec o tarea que la justifique y pasar el análisis de vulnerabilidades del pipeline.

## 4. Arquitectura

Vista→ViewModel→caso de uso/repositorio→adaptador remoto/local. El servidor sigue autorizando y moderando. Estado de sesión y caché se purga por cuenta; el cliente no simula aceptación de contraparte en compilaciones de producción (ver §11, excepción de datos de ejemplo). Todo acceso remoto pasa por la interfaz `NexoApi`; las pantallas no usan Dio directamente.

## 5. Contratos y datos

Autoridad de inventario: `API_NexoLocal/docs/contracts/inventario.json`. OpenAPI/AsyncAPI/SDL formales pendientes por incremento. docs/endpoints indexa, no sustituye los esquemas. IDs y dinero/fechas según contratos de Nexo, sin copiar prefijos SQL ni PascalCase legacy. Regla de teléfono/domicilio por estado y consentimiento.

## 6. Configuración y seguridad

Sin secretos en archivos, errores o logs. Configuración por entorno. Redis no es historial durable ni una caché expulsable para revocación. Moderar antes de persistir contenido; rechazar por omisión cuando no se puede comprobar autorización. CORS/headers web se aplican a superficies HTTP pertinentes; no inventar antiforgery de Razor para Flutter.

## 7. Gobernanza SDD

Flujo `specs/NNN-slug/spec.md → plan.md → tasks.md → checklist.md`. Un cambio pequeño por revisión, tareas con FR/NFR y aceptación verificable. Docs vivos en docs/, especificaciones los enlazan. Rama de trabajo futura según id de spec. Un revisor humano real; no copiar firmas del profesor. Borrador documental → refinada → lista para desarrollar → implementada con evidencia → aprobada; Borrador con evidencia solo tras ejecutar producto y documentar resultados.

Cada FR/NFR debe aparecer en una tarea definida y cada AC tener comprobación asignada. No citar tareas ausentes ni mantener dependencias circulares. La cobertura de diseño queda en tabla por spec; plan y checklist deben usar los mismos IDs. Las capacidades transversales tienen dueño único y los recorridos enlazan su integración.

## 8. Gates de calidad

Gates reales definidos en `.github/workflows/app-ci.yml` (generado por `tools/ci/generar_pipeline.py`, ver [pipeline](docs/pipeline.md)): formato → análisis → un job por cada archivo de prueba unitaria → un job por cada archivo de integración → un job por cada archivo de seguridad → herramientas de seguridad (gitleaks, OSV, manifiesto Android, revisión de workflows, revisión de dependencias en PR) → cobertura → APK → «CI · todo verde». Cobertura mínima 45% sobre la capa de lógica (base docente a ratificar; `MIN_COVERAGE` la ajusta). Ningún porcentaje sustituye casos críticos de permisos.

Los checks requeridos de las ramas protegidas salen de la misma lista que genera los jobs; no se editan a mano. No crear CI ficticio ni indicadores verdes sin ejecución: un gate cuenta solo cuando GitHub Actions lo ejecutó sobre el commit.

## 9. Entrega y operación

Nexo requiere CI/CD, nube, dos instancias HTTP, TLS, observabilidad, CDN y Play/landing, aunque los ejemplos pospongan hosting/CD y Redis. Costo cero se verifica con cuenta/región. Una publicación, pipeline o despliegue requiere el encargo correspondiente. El encargo de 2026-11-08 autoriza preparar CI/CD de la app: rulesets, entornos y variables por Terraform (`infra/github`), firma solo en el entorno `firma`, Play interna desde release/* (entorno `staging`) y producción desde main (entorno `production`, con revisor). Ver [Play Store](docs/play-store.md). Preparar no es publicar: la primera carga en Play Console es manual y cada publicación se registra en Memoria con el enlace a la ejecución.

## 10. Memoria

Memoria.md registra Estado, Decisiones con porqué, Deuda y A evitar por fase. Breve, sin datos sensibles. Una regla permanente se documenta en constitución/AGENTS. No confundir esta bitácora de proyecto con la memoria global del asistente.

## 11. Revisión y excepciones

Registrar diferencia con el profesor y razón de producto, manteniendo formato y secuencia. Ratificar stack/proveedores y responsable antes de Ready del primer incremento. Controles propuestos y escenarios de aceptación no son pruebas ejecutadas.

Excepción registrada (2026-11-08) — datos de ejemplo: mientras el backend publica endpoints, la app puede responder con la maqueta en memoria por grupo de API (spec 045). Condiciones: (a) solo se activa por indisponibilidad (red, 404/405/501 sin código Nexo, 5xx sin código Nexo o respuesta no JSON), nunca ante un error de negocio; (b) la pantalla muestra un aviso visible de «datos de ejemplo»; (c) la simulación de contraparte (interés, aceptación, respuesta de chat) solo existe en depuración o con `API_MODE=fake`, nunca en release con `auto`/`live`; (d) nada producido en ese modo cuenta como evidencia de integración.

## 12. Herramientas y coordinación acordadas

El equipo utilizará Codex y Claude Code. AGENTS es el procedimiento común y CLAUDE es entrada de lectura, sin duplicar reglas. Ejecución secuencial y revisión humana; roles documentados no activan subagentes.

Aplicar el [acuerdo SDD](../docs_nexo/SDD_ALINEACION.md), [cobertura de requisitos](../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [protocolo IA](../docs_nexo/SDD_HERRAMIENTAS_IA.md). La matriz de versiones precede al desarrollo; CI/CD y canal móvil se preparan desde primera vertical, mientras entrega cierra evidencia global. Mantener propuestas técnicas como tales hasta ratificar y resolver bloqueantes de la historia antes de Ready.

La spec 016-sincronizacion-local es autoridad de cola/migraciones/reconciliación; los recorridos conservan negocio y la API sus permisos. El cierre 014 incluye esta capacidad obligatoria; no habilita pedidos/contacto offline.

## Flujo Git del equipo (acuerdo 2026-11-02)

Aplicar [flujo Git](docs/flujo-git.md): ramas por tarea desde develop, PR a develop, candidato release/* y PR de release a main; reintegrar main a develop. main permanece principal. CI y PR obligatorios; revision independiente exigible al incorporar revisor real. No declarar Ready o aceptacion por publicar o fusionar documentacion.

## Trazabilidad de cambios Jira/Confluence (2026-11-02)

Aplicar [convencion de cambios](docs/trazabilidad-jira-confluence.md): rama de trabajo con clave Jira y PR con titulo/clave coincidentes, enlace al ticket y enlace obligatorio a la pagina Confluence del cambio. API y app conservan su autoridad SDD; Confluence no reemplaza contratos versionados. No inventar tickets, enlaces ni firmas; activar el check requerido solo con configuracion real y ejecucion verificada.

## 13. Pruebas en tres capas (2026-11-08)

`test/unit` (lógica pura y maqueta, sin red), `test/integration` (cliente HTTP real contra un adaptador Dio en memoria con las formas de `docs/endpoints`, sesión e interceptores) y `test/security` (secretos, transporte, enlaces profundos, registros, cabeceras/subidas y privacidad). Cada archivo es un job propio en el pipeline. Agregar un archivo de prueba exige regenerar el pipeline; `infra.yml` falla si quedó desactualizado. Ver [pantallas y pruebas](docs/pantallas-y-pruebas.md).

## 14. Resiliencia de consumo (2026-11-08)

`HybridNexoApi` decide por grupo (`API_MODE`=auto|live|fake, `LIVE`, `FAKE`). En `auto`, un grupo sin respuesta pasa a datos de ejemplo durante 60 s y vuelve a intentar el backend; un error de negocio siempre llega a la pantalla. Release exige URL HTTPS sin credenciales. La spec 045 es la autoridad de esta regla.

## 15. CI/CD como código (2026-11-08)

Protección de ramas, entornos, variables y nombres de secretos se declaran en Terraform (`infra/github`); el estado y el token nunca se versionan. Las acciones de terceros se fijan por SHA. La keystore, la cuenta de servicio de Play y las URLs se guardan solo como secretos/variables de GitHub. Specs 046–048 son la autoridad de estas reglas.

## 16. IA generativa y ML (2026-11-08)

La app tiene dos funciones distintas (spec 049): ML en el teléfono para sugerir la categoría por foto, con abstención y corrección manual, y un borrador generativo remoto por `POST /v1/assist/draft` que nunca publica solo. El texto que sale hacia la IA va sin teléfono, correo, enlaces ni domicilio. La app no guarda llaves de proveedores de IA. En release, si el asistente no responde se informa; no se generan plantillas presentadas como IA.

## 17. Push, caché local y producción (2026-11-08)

Push con Firebase: se guarda el `deviceId`, nunca el token; se da de baja al cerrar sesión (spec 050). La caché y la cola locales son por cuenta, mínimas y se borran al salir; pedidos, contacto y chat no funcionan sin conexión (spec 051). El AAB de producción exige backend y landing HTTPS, Firebase y una versión presente en la matriz `docs/versionamiento.md` (spec 052).
