# Integración móvil con perfiles reales

Fecha: 2026-11-09. Spec [054](../specs/054-integracion-perfiles/spec.md). Autoridad backend: grupo 03-perfil-prestador, nv-06 parcial. No se modifica backend, secretos ni infraestructura en este incremento.

| Recorrido | Operación / comportamiento |
|---|---|
| Cuenta → crear perfil profesional | POST /v1/discovery/providers, llave UUID, campos por tipo; después cambio de modo y refresh OAuth existentes |
| Cuenta → Mi perfil prestador | GET /v1/discovery/providers/me. Solo provider.not_found significa que falta el perfil; errores de red/servidor se muestran |
| Perfil público | GET /v1/discovery/providers/{id}, coordenadas del contexto de búsqueda; nunca se solicita /providers/me como ID público |
| Editar nombre | PATCH basic; no mezcla bio con esta sección |
| Acerca de / servicios | PATCH services: bio, actividad del negocio y categorías/especialidades de persona |
| Zona | PATCH zone, usando ubicación propia al abrir el selector; no reutiliza el punto difuminado como origen privado |
| Horario / precios / condiciones | PATCH hours/prices/terms con slugs, importes en centavos, pagos y canales consentidos |
| Comparación | GET providers/compare con dos IDs y contexto geográfico; best null se conserva |
| Fotos/portada | Próximamente hasta habilitar almacenamiento y moderación. No hay subida o guardado ficticio |

## Contratos corregidos

El adaptador convierte etiquetas de especialidades a slugs del catálogo inicial del backend. `provider_contract.dart` conserva este mapeo temporal mientras el bloque 04 expone el catálogo público; los formularios muestran etiquetas legibles. En negocio, categorías se infieren en el servidor desde actividad/bio. La edición de actividad limpia las especialidades al recalcular categorías; selección avanzada de especialidades de negocio permanece pendiente del catálogo autoritativo.

Visit.amountCents y minPrice.fromCents se interpretan aunque no exista campo text. Los formularios preservan dos decimales, distinguen cotización/null y rechazan importe vacío en vez de convertirlo en gratis. Pagos y responseTime conservan slugs al editar sin cambios. Perfil propio conserva policyVersion; contactClicks null se muestra como raya.

El alta mantiene la llave en reintentos de red; un rechazo 4xx permite nueva intención corregida. Una vez recibida la creación, un fallo posterior de cambio de modo reintenta el cambio de modo sin repetir POST. Moderación caída/rechazada permanece como fallo del servidor; no se simula aprobación.

## Privacidad y modo real

El grupo perfil usa HTTP en auto y live; fake solo se usa al seleccionarlo explícitamente. Fallos de otro grupo no activan el aviso de demo para perfiles. Las lecturas de perfiles se excluyen de la caché SQLite y no recuperan datos privados sin conexión, acorde con no-store del backend actual. Escrituras de perfil no entran a la cola offline.

## Verificación

Se amplían archivos actuales: unit/models_test.dart y diseno_maqueta_test.dart; integration/http_perfil_test.dart, cache_sin_conexion_test.dart y resiliencia_test.dart; security/privacidad_test.dart. No se añadieron archivos de prueba ni se cambia el grafo de CI por este incremento. Pruebas HTTP móviles usan adaptador Dio en memoria y widgets; no equivalen a usar una cuenta real con Atlas/Azure/Gmail ni a recorrer Android.

237 pruebas aprobadas con cobertura (12 nuevas); analizador sin errores ni warnings, 13 infos pendientes. WORKFLOWS-OK y diff --check aprobados. SDD mantiene enlaces históricos rotos; la spec 054 no añade fallos propios. No se afirma aceptación humana, publicación ni configuración de Content Safety/Blob/CDN. La ejecución de check_sdd conserva fallos históricos de enlaces externos; su validación documental no sustituye pruebas de producto.

## Cómo probar localmente

1. Iniciar el backend actualizado desde NexoLocalApi con `dotnet run --project src/Host/Nexo.Host --launch-profile Api` (http://127.0.0.1:5188).
2. Android físico con USB: `adb reverse tcp:5188 tcp:5188`.
3. Desde src/mobile/nexo_app: `flutter run --dart-define=API_MODE=live --dart-define=API_BASE_URL=http://127.0.0.1:5188`.
4. Iniciar sesión y abrir Cuenta → crear perfil profesional. Para publicar texto debe estar configurado Content Safety en el entorno del backend; si falta, 503 explícito. No habilitar fake para ocultarlo.

Búsqueda/listados y trabajos/opiniones siguen pendientes de sus endpoints, por lo que el alta y perfil propio se prueban desde Cuenta. Perfil público/comparación consumen rutas reales cuando se dispone de IDs reales; la integración no crea resultados de búsqueda ficticios para presentar el recorrido como terminado.

## Resultado de compilación y arranque

APK debug construido en modo live apuntando a http://127.0.0.1:5188. Instalado conservando datos en Android conectado (adb install -r: Success), reverse USB 5188 configurado y actividad abierta con Status: ok. API local iniciada con el código actualizado: OpenAPI publica las cinco rutas y /health/ready responde 200. Esto comprueba instalación, arranque y disponibilidad; el alta/edición con la cuenta real del usuario y moderación cloud siguen sin acreditarse.
