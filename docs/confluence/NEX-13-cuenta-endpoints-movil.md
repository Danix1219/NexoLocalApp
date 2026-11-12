# NEX-13 — Integración móvil de cuenta, descubrimiento y medios

**Estado:** listo para publicar en Confluence.  
**Sprint:** Scrum Sprint 2 (11–25 de noviembre de 2026).  
**Repositorio:** `Danix1219/NexoLocalApp`.  
**Rama:** `feature/NEX-13-041-cuenta-modo-celular-baja`.  
**PR:** #17 hacia `develop`.

## Objetivo

Conectar la aplicación Flutter con los endpoints disponibles de cuenta, descubrimiento, trabajos y solicitudes, manteniendo el manejo de errores reales. Alinear el estado de los medios con la infraestructura de Blob Storage, CDN y moderación asociada a NEX-13.

## Cambios realizados

### Consumo de API

- Se conserva el consumo real de Cuenta: `GET` y `PATCH /v1/identity/me`, cambio de modo, celular y baja de cuenta.
- Se conectaron los flujos de descubrimiento, perfiles, trabajos y solicitudes mediante `NexoApi`/`HttpNexoApi`, Riverpod y las pantallas existentes.
- Catálogo, filtros y estados de carga/error se conservan contra el backend. No se reemplazan con datos de ejemplo ante una respuesta de negocio o de red.
- Los cursores de listas se recorren de forma secuencial y se rechazan cursores repetidos o faltantes.

### Cuenta y medios

- La edición de cuenta sigue actualizando el nombre mediante `PATCH /v1/identity/me`.
- La foto existente devuelta por la API se muestra, pero la pantalla no inicia nuevas cargas ni envía `photoUploadId` mientras Blob/CDN y moderación no estén operativos extremo a extremo.
- Al tocar el avatar se muestra un mensaje claro de disponibilidad próxima; no se simula una carga exitosa.
- Este bloqueo temporal no cambia el catálogo remoto ni la autorización del backend.

## Contratos y compatibilidad

La autoridad de contratos está en NexoLocalApi. La aplicación consume los contratos publicados y mantiene compatibilidad de payload para `PATCH /v1/identity/me`; simplemente omite el campo opcional `photoUploadId` desde la pantalla de cuenta hasta disponer de infraestructura de medios validada.

La infraestructura de NEX-13 es una dependencia para habilitar de nuevo la carga de avatar y portada. No se incluyeron claves de Azure, SAS, secretos ni acceso directo a almacenamiento desde la aplicación.

## Validación realizada

| Comprobación | Resultado |
|---|---|
| `flutter test --reporter expanded test/integration/http_perfil_test.dart` | 12 pruebas aprobadas. |
| `flutter test --reporter expanded test/integration/http_cuenta_test.dart test/security/privacidad_test.dart` | 20 pruebas aprobadas. |
| `dart format` sobre los archivos modificados | Sin cambios pendientes. |
| CI de formato de la PR antes de este ajuste | Aprobada. |

Las pruebas HTTP emplean dobles de Dio; validan contratos, rutas y manejo de fallos. No acreditan una carga de imagen física, CDN, Blob Storage, moderación externa ni recorrido completo en un dispositivo.

## Riesgos y siguientes pasos

1. Completar y validar NEX-13: Blob Storage, CDN y moderación de medios.
2. Probar carga, rechazo y reemplazo de avatar/portada con una cuenta real y recursos temporales.
3. Cuando esa validación exista, volver a habilitar la selección de avatar y el envío de `photoUploadId` con manejo de rechazo conservando la foto anterior.
4. Añadir el permalink de esta página al cuerpo de la PR #17 para completar la trazabilidad obligatoria.

## Registro de cambios

| Fecha | Cambio |
|---|---|
| 2026-11-10 | Integración de endpoints de descubrimiento, trabajos y solicitudes en la app. |
| 2026-11-11 | Se ajusta Cuenta para no iniciar cargas de avatar hasta contar con infraestructura de medios y moderación verificadas; se mantiene catálogo remoto. |
