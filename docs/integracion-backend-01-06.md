# Integración móvil con backend disponible — 2026-11-10

| Grupo | Consumo y pantallas |
|---|---|
| 01/02 identidad y cuenta | Se conserva autenticación/cuenta/ubicación real previas. Sin modificar secretos ni contratos. |
| 03 perfil | Alta, consulta, comparación y edición existentes; selectores usan catálogo servidor. |
| 04 descubrimiento | GET categories con envelope categories y especialidades; search/providers, search/suggest, map/nearby, ubicación/geocoding previos. Filtros, mapa de ambos roles y apertura de solicitud real. feed sigue Próximamente por backend ausente. |
| 05 trabajos | POST works con clave estable, GET providers/{id}/works con todos los cursores, DELETE propio y POST/DELETE recommend accesibles en perfil público. Autor real compuesto con perfil ya leído. |
| 06 solicitudes | POST requests, GET mine, GET opportunities y POST close; estado/refresco en Inicio, Buscar y Mi perfil. Filtros coinciden con backend y local radio 0 usa 10 km. |

Autoridad: [estado backend](../../../nexolocal_api/NexoLocalApi/docs/estado-desarrollo-endpoints.md), [incremento 06](../../../nexolocal_api/NexoLocalApi/specs/endpoints/06-solicitudes/implementacion.md). [Spec móvil 057](../specs/057-integracion-descubrimiento-trabajos-solicitudes/spec.md).

Decisiones: NexoApi/HttpNexoApi → Riverpod → pantallas actuales. Los grupos publicados no pasan a demo por error/red; fake sigue explícito. Listas existentes recorren páginas secuencialmente, rechazan cursores repetidos/faltantes y no truncan a la primera página. Catálogo cargando/error/reintento visible. Mutaciones mantienen sus claves por payload; cambiar payload genera otra clave después de un intento. Ubicación del servicio elegida o guardada real obligatoria; trabajo usa ubicación propia privada, nunca punto público difuminado como sustituto. Cierre envía pickedProviderId solo en solvedHere y refresca actividad; no habilita reseñas.

Fotos/portada: Próximamente hasta infraestructura real. Sin fotos se omite carrusel, no se agrega foto demo. Interés/guardados pendientes muestran indisponibilidad real/Próximamente; no equivalen a endpoints implementados. Resumen degradado conserva interés desconocido. Listas de solicitudes/trabajos, búsquedas y mapas no se recuperan de caché privada obsoleta; logs Discovery omiten consultas/coordenadas. Publicación offline de solicitud conserva la cola/idempotencia previa y se distingue de publicación confirmada.

## Verificación
`flutter test --no-pub --coverage`: 260 pruebas aprobadas, 10 casos nuevos, en test/unit, test/integration y test/security existentes. Cobertura generada en coverage/lcov.info. Dobles Dio para contratos y fallos externos; no es ejecución remota del backend. Las primeras ejecuciones detectaron fixtures de catálogo y una expectativa visual antigua que inventaba foto; corregidos con regresión completa aprobada.

`flutter analyze --no-pub`: sin errores/warnings y 12 avisos informativos previos (salida no cero de Flutter por diagnósticos informativos, no se presenta como análisis sin observaciones). `python tools/ci/revisar_workflows.py`: WORKFLOWS-OK. `git diff --check`: 0. No se crearon archivos de test/jobs nuevos ni se regeneró o aplicó Terraform. `scripts/check_sdd.ps1` conserva fallos históricos por enlaces externos/estado documental; no se declara SDD-OK global.

APK debug live compilado para API_BASE_URL=http://127.0.0.1:5188; instalado con adb install -r en el teléfono conectado conservando datos; reverse USB 5188, arranque Status: ok y proceso activo. Logcat del proceso sin AndroidRuntime:E/flutter:E en la comprobación de arranque. Recorrido físico completo con cuenta real, entrega correo, moderación externa y aceptación visual humana pendientes. Comprobación actual de API /health/ready: HTTP200; sustituye el ready503 histórico del incremento backend anterior. No se cambió configuración de Mongo por esta tarea. No se cambian conexiones ni se siembran usuarios/contenido.


## Medios reales, 2026-11-10
Se habilita galer?a para avatar y portada, edici?n profesional y publicaciones. HttpNexoApi solicita SAS, sube sin Bearer, confirma y espera estado approved; luego adjunta uploadId con los contratos actuales. Portada personal GET/PUT /v1/discovery/me/cover. Errores/rechazo mantienen foto o borrador anterior. No se incluye conexi?n ni claves Azure en APK. Fotos no usan cach? offline de JSON privado.
Validaci?n de Azure separada en backend con imagen sint?tica y limpieza final; suite m?vil usa dobles HTTP, no acredita selecci?n f?sica en el tel?fono. CDN y adjuntos privados de chat fuera de alcance.

Cierre t?cnico de medios: Flutter267/267, analyze0errores/0warnings con13infos existentes. APKdebug/live instalado conservando datos y abierto; backendready200. Sin acreditaci?n de cada interacci?n f?sica.
