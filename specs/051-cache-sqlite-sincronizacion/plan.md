# Plan — 051-cache-sqlite-sincronizacion

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-051-cache-sqlite-sincronizacion`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/core/local/local_store.dart
  lib/core/local/sqflite_store.dart
  lib/core/local/offline_interceptor.dart
  lib/core/local/sync_controller.dart
  lib/core/network/api_client.dart
  lib/core/auth/session_controller.dart
  lib/features/shell/shell_page.dart
  test/integration/cache_sin_conexion_test.dart
  test/integration/sincronizacion_test.dart
  test/unit/almacen_local_test.dart
  test/security/cache_local_seguro_test.dart
```

## 2. Contratos (rutas, config, env)

- GET `/v1/** (lecturas)` — grupo `todos`: caché por cuenta.
- POST `/v1/discovery/requests` — grupo `solicitudes`: cola sin señal.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/core/local/local_store.dart` | Interfaz de caché/cola por cuenta y versión en memoria. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/local/sqflite_store.dart` | SQLite con tablas de caché y cola. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/local/offline_interceptor.dart` | Interceptor Dio: caché, ETag, sin señal y cola. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/local/sync_controller.dart` | Envío de la cola al reconectar y estado sin conexión. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/network/api_client.dart` | Dio con autenticación y caché sin conexión. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/core/auth/session_controller.dart` | Estados unknown/signedOut/guest/signedIn, modo y nombre. | FR-001, FR-002, FR-003, FR-004, FR-005 |
| `lib/features/shell/shell_page.dart` | Shell con barra inferior, globo de no leídos, sondeo y aviso de datos de ejemplo. | FR-001, FR-002, FR-003, FR-004, FR-005 |

Decisiones de diseño:

- Caché en el borde HTTP (interceptor Dio) para cubrir todas las pantallas sin tocarlas.
- Cola solo para publicar solicitud, con la misma `Idempotency-Key` para no duplicar.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Integración | `test/integration/cache_sin_conexion_test.dart` | Integración · cache-sin-conexion |
| FR-001 | Integración | `test/integration/sincronizacion_test.dart` | Integración · sincronizacion |
| FR-001 | Unidad | `test/unit/almacen_local_test.dart` | Unidad · almacen-local |
| FR-002 | Integración | `test/integration/cache_sin_conexion_test.dart` | Integración · cache-sin-conexion |
| FR-002 | Integración | `test/integration/sincronizacion_test.dart` | Integración · sincronizacion |
| FR-002 | Unidad | `test/unit/almacen_local_test.dart` | Unidad · almacen-local |
| FR-003 | Integración | `test/integration/cache_sin_conexion_test.dart` | Integración · cache-sin-conexion |
| FR-003 | Integración | `test/integration/sincronizacion_test.dart` | Integración · sincronizacion |
| FR-003 | Unidad | `test/unit/almacen_local_test.dart` | Unidad · almacen-local |
| FR-004 | Integración | `test/integration/cache_sin_conexion_test.dart` | Integración · cache-sin-conexion |
| FR-004 | Integración | `test/integration/sincronizacion_test.dart` | Integración · sincronizacion |
| FR-004 | Unidad | `test/unit/almacen_local_test.dart` | Unidad · almacen-local |
| FR-005 | Integración | `test/integration/cache_sin_conexion_test.dart` | Integración · cache-sin-conexion |
| FR-005 | Integración | `test/integration/sincronizacion_test.dart` | Integración · sincronizacion |
| FR-005 | Unidad | `test/unit/almacen_local_test.dart` | Unidad · almacen-local |
| NFR-001 | Seguridad | `test/security/cache_local_seguro_test.dart` | Seguridad · cache-local-seguro |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Integración · cache-sin-conexion» · «Integración · sincronizacion» · «Unidad · almacen-local» · «Seguridad · cache-local-seguro» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- La caché SQLite no está cifrada; se mitiga con almacenamiento privado, `allowBackup=false`, datos mínimos y borrado al salir.
- Mostrar datos viejos sin señal: el aviso con la hora lo deja claro.

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
