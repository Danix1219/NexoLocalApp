# Plan — 050-notificaciones-push

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-050-notificaciones-push`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
  lib/features/push/push_controller.dart
  lib/features/push/push_gateway.dart
  lib/features/push/firebase_push_gateway.dart
  lib/features/shell/shell_page.dart
  lib/features/account/account_page.dart
  lib/core/auth/token_storage.dart
  lib/app/app.dart
  test/integration/push_controlador_test.dart
  test/unit/push_mensajes_test.dart
  test/security/push_seguro_test.dart
```

## 2. Contratos (rutas, config, env)

- POST `/v1/identity/devices` — grupo `dispositivos`: registrar teléfono.
- DELETE `/v1/identity/devices/{id}` — grupo `dispositivos`: dar de baja.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `lib/features/push/push_controller.dart` | Permiso, registro del teléfono, avisos en primer plano y apertura por enlace. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/push/push_gateway.dart` | Frontera con el proveedor de push y mensaje reducido. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/push/firebase_push_gateway.dart` | Implementación con Firebase Cloud Messaging. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/shell/shell_page.dart` | Shell con barra inferior, globo de no leídos, sondeo y aviso de datos de ejemplo. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/features/account/account_page.dart` | Cuenta de cliente, prestador y visitante; modo, salir y eliminar. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/core/auth/token_storage.dart` | Tokens, nombre y modo en almacenamiento seguro; limpieza al salir. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |
| `lib/app/app.dart` | Arranque de push y sincronización. | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006 |

Decisiones de diseño:

- Frontera `PushGateway` para probar sin Firebase.
- Se guarda el `deviceId`, nunca el token FCM, y el token no se escribe en registros.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-001 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-001 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| FR-002 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-002 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-002 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| FR-003 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-003 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-003 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| FR-004 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-004 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-004 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| FR-005 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-005 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-005 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| FR-006 | Integración | `test/integration/push_controlador_test.dart` | Integración · push-controlador |
| FR-006 | Unidad | `test/unit/push_mensajes_test.dart` | Unidad · push-mensajes |
| FR-006 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| NFR-001 | Seguridad | `test/security/push_seguro_test.dart` | Seguridad · push-seguro |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Integración · push-controlador» · «Unidad · push-mensajes» · «Seguridad · push-seguro» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Requiere proyecto de Firebase y su `google-services.json` como secreto del entorno `firma`.
- El contenido del aviso lo define el backend: no debe llevar domicilio ni teléfono (contrato de notificaciones).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-014 → T-015 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
