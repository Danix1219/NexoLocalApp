# Pantallas, specs y pruebas — app 0.5.0

Mapa vivo de cada pantalla o función de la maqueta V1.00.002 con su spec, su código en `src/mobile/nexo_app` y los jobs del pipeline que la verifican. Spec 047 genera los jobs; si cambias una prueba, actualiza esta tabla.

| Spec | Pantalla o función | Endpoints (grupo) | Pruebas → jobs |
|---|---|---|---|
| [026](../specs/026-shell-navegacion-visitante/spec.md) | Barra inferior, navegación y modo visitante | `mensajes`, `notificaciones` | Integración · sesion<br>Seguridad · enlaces-profundos<br>Seguridad · privacidad |
| [027](../specs/027-inicio-cliente/spec.md) | Inicio del cliente: Para ti, Mis solicitudes y Mis servicios | `descubrimiento`, `guardados`, `pedidos`, `solicitudes`, `trabajos` | Unidad · fake-discovery<br>Unidad · models<br>Integración · http-descubrimiento<br>Integración · http-solicitudes-interes |
| [028](../specs/028-inicio-prestador/spec.md) | Inicio del prestador: Comunidad, Oportunidades y pedidos por responder | `interes`, `pedidos`, `perfil`, `solicitudes` | Unidad · fake-requests<br>Unidad · filters<br>Integración · http-solicitudes-interes<br>Integración · http-pedidos |
| [029](../specs/029-buscar-prestadores/spec.md) | Buscar prestadores: texto, sugerencias, filtros, lista y mapa | `descubrimiento` | Unidad · fake-discovery<br>Unidad · filters<br>Integración · http-descubrimiento |
| [030](../specs/030-ubicacion-mapa-radio/spec.md) | Ubicación de búsqueda y zona: selector de mapa, radio y GPS | `descubrimiento` | Unidad · fake-discovery<br>Integración · http-descubrimiento |
| [031](../specs/031-perfil-prestador/spec.md) | Perfil público del prestador: Trabajos, Información y Opiniones | `opiniones`, `perfil`, `trabajos` | Unidad · models<br>Integración · http-perfil<br>Integración · http-pedidos |
| [032](../specs/032-mi-perfil-edicion/spec.md) | Mi perfil de prestador: completitud y edición por sección | `imagenes`, `perfil`, `trabajos` | Unidad · fake-account<br>Integración · http-perfil<br>Integración · http-imagenes |
| [033](../specs/033-comparar-prestadores/spec.md) | Comparar dos prestadores lado a lado | `perfil` | Unidad · fake-discovery<br>Integración · http-perfil |
| [034](../specs/034-contacto-reportes-senales/spec.md) | Contactar, ver número, reportar y señales de confianza | `contacto`, `mensajes` | Integración · http-guardados-contacto<br>Integración · http-mensajes<br>Seguridad · cabeceras-y-subidas |
| [035](../specs/035-publicar-solicitud/spec.md) | Publicar «Busco un servicio» | `imagenes`, `solicitudes` | Unidad · publish-rules<br>Unidad · fake-requests<br>Integración · http-solicitudes-interes |
| [036](../specs/036-publicar-trabajo/spec.md) | Publicar un trabajo realizado (prestador) | `imagenes`, `trabajos` | Integración · http-imagenes<br>Integración · http-solicitudes-interes<br>Seguridad · cabeceras-y-subidas |
| [037](../specs/037-experiencia-calificacion/spec.md) | Mi experiencia y calificación de un servicio resuelto | `opiniones`, `pedidos` | Unidad · fake-orders<br>Integración · http-pedidos |
| [038](../specs/038-interes-e-interesados/spec.md) | «Me interesa», lista de interesados y cierre de solicitud | `interes`, `solicitudes` | Unidad · fake-requests<br>Integración · http-solicitudes-interes |
| [039](../specs/039-pedido-servicio/spec.md) | Pedido de servicio: pedir, aceptar, rechazar, cancelar, resolver y domicilio | `contacto`, `pedidos` | Unidad · fake-orders<br>Integración · http-pedidos<br>Seguridad · privacidad<br>Seguridad · cabeceras-y-subidas |
| [040](../specs/040-mensajeria-chat/spec.md) | Mensajes: bandeja y chat | `mensajes` | Unidad · fake-messages<br>Integración · http-mensajes |
| [041](../specs/041-cuenta-modo-celular-baja/spec.md) | Cuenta: modo cliente/prestador, celular, privacidad, salir y eliminar | `auth`, `cuenta` | Unidad · fake-account<br>Integración · http-cuenta<br>Integración · sesion<br>Seguridad · privacidad |
| [042](../specs/042-guardados-recomendaciones/spec.md) | Guardados y recomendaciones | `guardados`, `trabajos` | Unidad · fake-account<br>Integración · http-guardados-contacto<br>Integración · http-solicitudes-interes |
| [043](../specs/043-notificaciones-bandeja/spec.md) | Notificaciones dentro de la app | `notificaciones` | Unidad · fake-account<br>Integración · http-guardados-contacto<br>Seguridad · enlaces-profundos |
| [044](../specs/044-alta-prestador/spec.md) | Registro de prestador: tipo, datos, servicios, zona y listo | `cuenta`, `imagenes`, `perfil` | Unidad · fake-account<br>Integración · http-perfil |
| [045](../specs/045-resiliencia-consumo-api/spec.md) | Resiliencia del consumo: endpoints ausentes o sin señal sin error en pantalla | — | Unidad · api-modes<br>Integración · resiliencia |
| [046](../specs/046-pruebas-tres-capas-seguridad/spec.md) | Pruebas en tres capas: unidad, integración y seguridad | — | Unidad · (todos los archivos de la carpeta)<br>Integración · (todos los archivos de la carpeta)<br>Seguridad · (todos los archivos de la carpeta) |
| [047](../specs/047-ci-cd-github-terraform/spec.md) | CI/CD en GitHub Actions con grafo por prueba y Terraform | — | tools/ci/generar_pipeline.py --check<br>infra.yml (terraform validate) |
| [048](../specs/048-publicacion-play-store/spec.md) | Firma y publicación en Google Play | — | Construir · AAB firmado<br>Seguridad · AndroidManifest y build |
| [049](../specs/049-ia-generativa-y-ml/spec.md) | IA generativa (borrador editable) y ML en el teléfono | Publicar | Unidad · ml-categoria<br>Unidad · asistente-y-dispositivos-fake<br>Integración · http-asistente-dispositivos<br>Seguridad · ia-sin-datos-personales |
| [050](../specs/050-notificaciones-push/spec.md) | Notificaciones push de los procesos principales | Shell, Cuenta | Unidad · push-mensajes<br>Integración · push-controlador<br>Seguridad · push-seguro |
| [051](../specs/051-cache-sqlite-sincronizacion/spec.md) | Caché SQLite por cuenta y sincronización | Transversal | Unidad · almacen-local<br>Integración · cache-sin-conexion<br>Integración · sincronizacion<br>Seguridad · cache-local-seguro |
| [052](../specs/052-privacidad-landing-produccion/spec.md) | Privacidad en la landing, moderación, permisos y versionamiento | Cuenta | Seguridad · transporte<br>Seguridad · secretos-en-codigo<br>Versión · matriz y SemVer<br>Seguridad · AndroidManifest y build |

## Grupos de endpoints y modo de consumo

Cada grupo corresponde a una carpeta de `docs/endpoints` del backend. Con `API_MODE=auto` (de fábrica) la app intenta el backend y, si el endpoint todavía no existe o no hay señal, responde con los datos de la maqueta sin mostrar error ([spec 045](../specs/045-resiliencia-consumo-api/spec.md)).

| Grupo | Carpeta | Forzar backend | Forzar maqueta |
|---|---|---|---|
| `cuenta` | `02-cuenta` | `--dart-define=LIVE=cuenta` | `--dart-define=FAKE=cuenta` |
| `perfil` | `03-perfil-prestador` | `--dart-define=LIVE=perfil` | `--dart-define=FAKE=perfil` |
| `descubrimiento` | `04-descubrimiento` | `--dart-define=LIVE=descubrimiento` | `--dart-define=FAKE=descubrimiento` |
| `trabajos` | `05-trabajos` | `--dart-define=LIVE=trabajos` | `--dart-define=FAKE=trabajos` |
| `solicitudes` | `06-solicitudes` | `--dart-define=LIVE=solicitudes` | `--dart-define=FAKE=solicitudes` |
| `interes` | `07-interes` | `--dart-define=LIVE=interes` | `--dart-define=FAKE=interes` |
| `pedidos` | `08-pedidos` | `--dart-define=LIVE=pedidos` | `--dart-define=FAKE=pedidos` |
| `opiniones` | `09-opiniones` | `--dart-define=LIVE=opiniones` | `--dart-define=FAKE=opiniones` |
| `mensajes` | `10-mensajes` | `--dart-define=LIVE=mensajes` | `--dart-define=FAKE=mensajes` |
| `guardados` | `11-guardados` | `--dart-define=LIVE=guardados` | `--dart-define=FAKE=guardados` |
| `contacto` | `12-contacto-reportes` | `--dart-define=LIVE=contacto` | `--dart-define=FAKE=contacto` |
| `notificaciones` | `13-notificaciones` | `--dart-define=LIVE=notificaciones` | `--dart-define=FAKE=notificaciones` |
| `imagenes` | `14-imagenes-cdn` | `--dart-define=LIVE=imagenes` | `--dart-define=FAKE=imagenes` |
| `asistente` | EP-082 `/v1/assist/draft` | `--dart-define=LIVE=asistente` | solo depuración/`API_MODE=fake` (en release se informa no disponible) |
| `dispositivos` | `02-cuenta` (devices) | `--dart-define=LIVE=dispositivos` | `--dart-define=FAKE=dispositivos` (sin push) |

Login, registro y contraseña (`01-auth`) siempre van al backend.

Las lecturas de todos los grupos pasan además por la caché local por cuenta y la cola sin señal ([spec 051](../specs/051-cache-sqlite-sincronizacion/spec.md)): sin conexión se ve lo guardado antes de usar datos de ejemplo.
