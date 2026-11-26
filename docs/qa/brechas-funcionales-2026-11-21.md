# Revision funcional - 2026-11-21

Revision de codigo, contratos y pruebas locales. No constituye un recorrido completo de todas las pantallas en dispositivo.

| Hallazgo | Spec | Resolucion / pendiente |
|---|---|---|
| Me interesa bloqueado por modo live pese a existir endpoint | 038/060 | Retirado bloqueo; enviar/retirar y refrescar tras exito. Prueba de accion a HTTP |
| Interesados truncados a primera pagina | 038/060 | Recorrido de cursores con sort estable y deteccion de ciclos |
| Cabecera de busqueda estrecha y centrada | 029/060 | Ancho completo, ubicacion en dos lineas, sin texto territorial duplicado junto al contador |
| Respuestas antiguas de sugerencias | 029/060 | Solo aplicar si consulta coincide y foco sigue activo |
| Edicion duplicada en visor | 031/059/060 | Eliminada accion inferior; lapiz solo propietario; compartir/QR conservados en prestadores propios y ajenos |
| Fotos de Tu cuenta con aviso proximamente | 032/060 | Usa carga y actualizacion existentes; pendiente prueba real de moderacion |
| Mi experiencia sin accion e historial vacio artificial | 032/060 | Elegir pedido calificable y mostrar puntuaciones de pedidos reales; pendiente aceptacion real |
| Perfil publico de solicitante | Sin contrato publico actual | No publicar cuenta privada ni generar QR que no resuelva. Requiere definir datos publicos y consentimiento antes de implementar |
| Enlaces HTTPS universales | 052/059 | Pendiente dominio propio y asociacion Android/iOS. Esquema nexolocal:// funciona solo con app instalada |
| Datos de autor en guardados | 057 y API Discovery/Saved | Proyeccion publica no garantiza autor. Interfaz evita nombre inventado; falta contrato/proyeccion autorizada para mostrarlo siempre |
| Preferencias de categorias locales | 028/045 | InterestsController vive en telefono; no equivale al interes por una solicitud. Sin sincronizacion entre dispositivos |

Los metodos abstractos con UnimplementedError de NexoApi no prueban fallos de producto: comprobar sus overrides HTTP. Las excepciones explicitas de chat privado en FakeNexoApi evitan simular seguridad real. Las casillas abiertas de specs existentes incluyen revision humana/CI; no significan necesariamente ausencia de codigo.

## Evidencia local
82 pruebas aprobadas: diseno_maqueta_test.dart, http_solicitudes_interes_test.dart y http_perfil_test.dart. Adaptadores HTTP y widgets, sin servicios productivos. Falta aceptar en dispositivo Me interesa con dos cuentas, avatar moderado, valoracion de pedido y QR escaneado.

Validador SDD ejecutado: FAIL. Incluye enlaces historicos rotos, tareas de 040/041/050 y politica documental que rechaza tareas implementadas. No se declara SDD-OK.

Analisis de ocho archivos modificados: sin incidencias. Suite inicial 81 pruebas; regresion adicional de cursor repetido y suite de interes 12/12 aprobadas (82 casos distintos en total).

Compilacion APK debug live con API local: aprobada (assembleDebug 165 s). Aviso existente de compatibilidad futura de Kotlin 1.8.22; no impidio compilar. No acredita rendimiento o despliegue productivo.


### Actualizacion posterior: guardados y solicitante
La brecha de perfil compartido de solicitante tiene implementacion local: POST/GET/DELETE de opt-in en Identity y ruta profile en app, con nombre/foto exclusivamente. Guardados ahora enriquece autores de trabajo y solicitud con proyeccion publica y puertos. 66 pruebas Flutter y tres pruebas Mongo aprobadas. Sustituye el estado pendiente de esas dos filas; aceptacion humana y reinicio API aun pendientes.


### Solicitudes, copiado y mapa - continuacion
- Tres puntos abre menu antes de editar; eliminar exige confirmar y muestra error recuperable dentro de la hoja. DELETE real retira la publicacion sin falsear una solicitud resuelta ni borrar pedidos; asignada se rechaza.
- Creacion y edicion comparten autoTitle derivado del contenido; se elimina el campo visual Titulo de solicitudes y trabajos, y la cabecera duplicada de las tarjetas cuando ya hay contenido. El campo contractual sigue por compatibilidad.
- Visor de perfil tiene ScaffoldMessenger propio: el aviso de enlace copiado aparece encima del visor y no en la pantalla posterior.
- MiniMap conserva coordenadas y dispone de fallback OSM, user-agent de app y atribucion. Servidores Esri y OSM devolvieron 200 y bytes de imagen para zona/zoom16 del pedido; esto no prueba renderizado en telefono.
- Validacion: 76 pruebas Flutter aprobadas; analisis de diez archivos limpio. API: 67 unitarias Discovery y una integracion Mongo de borrado seguro aprobadas. Compilacion/instalacion y aceptacion visual se registran aparte.

APK debug live compilado correctamente (assembleDebug 58 s). Instalacion Xiaomi aprobada; Motorola en curso al registrar esta nota. Requiere reiniciar API local para DELETE solicitudes. No se ha verificado visualmente el mapa en dispositivo.

Motorola: streaming fallo; reintento --no-streaming -r aprobo (Success) y actividad iniciada. Ambos telefonos actualizados sin borrar datos.


## Perfiles y publicaciones consistentes - 2026-11-21
Estado: trabajos propios usan WorkCard completa, con menu Editar/Eliminar y confirmacion con vista previa, progreso y errores recuperables. Marco redondeado compartido con solicitudes propias. Ya no se infiere propiedad de canContact=false; se comprueba identidad del prestador o contexto propio confirmado.
Fotos es una pestana independiente: Trabajos, Fotos, Informacion, Opiniones. Galeria de tres columnas con todas las imagenes de publicaciones y portfolio, sin duplicados por URL, apertura individual y estado vacio. Las solicitudes eliminan el banner TU SOLICITUD redundante y conservan estado, categoria, urgencia y acciones.
Validacion: dart format de 4 archivos; flutter analyze --no-pub de esos archivos sin incidencias; flutter test --no-pub test/unit/diseno_maqueta_test.dart: 65 aprobadas. git diff --check de los archivos modificados sin incidencias. scripts/check_sdd.ps1 sigue fallando por enlaces historicos a API_NexoLocal; no se declara PASS.
Pendiente: aceptacion visual humana en ambos telefonos. Sin cambios de contratos ni despliegue de API en este incremento.

Entrega del incremento: APK debug live compilado correctamente (assembleDebug 42.3s), API_BASE_URL local 5188. Instalacion --no-streaming -r: Success en Xiaomi 096fd2cc784f y Motorola ZY32JKH7KW; MainActivity iniciada en ambos. Datos conservados. Esto acredita compilacion e instalacion, no aceptacion visual humana.


## Cabecera horizontal de busqueda - 2026-11-21
SearchHeader compartido por solicitante y prestador: titulo izquierdo de 20px con ajuste natural de lineas, ubicacion derecha de 12px, espacios flexibles 5:6 y centros alineados. Ubicacion completa disponible en tooltip; conserva accion para cambiar zona. Prueba focalizada diseno_maqueta_test: aprobada a 320/390px, texto 1.3x, titulo sin superar dos lineas. Analisis de los dos archivos sin incidencias. Aceptacion visual humana pendiente.

Entrega cabecera: APK debug live compilado (23s) e instalado con Success y MainActivity iniciada en Xiaomi y Motorola. git diff --check de ambos archivos correcto.


## Interesados y comparacion coherente - 2026-11-21
Estado: interesados separa resumen de solicitud, propuesta del prestador y acciones. Comparar es un boton con texto y estado En comparacion, tarjeta seleccionada con borde de marca. Reutiliza toggleCompare, compareProvider y CompareBar del feed, sin seleccion paralela. Barra fuera del listado (Column/Expanded) para reservar espacio y evitar superposicion; el mismo CompareBar compartido distribuye seleccion y accion en dos filas, conservando limite de dos y limpieza.
Ubicacion de SearchHeader: maxLines 1, elipsis y pastilla redondeada; conserva tooltip y cambio de zona en ambos modos.
Validacion: 79 pruebas aprobadas (diseno_maqueta_test.dart + http_solicitudes_interes_test.dart). Nueva prueba recorre InterestedPage, selecciona/quita, elige dos, navega a ComparePage y verifica GET compare con ids pro-1,pro-2 y respuesta renderizada. Dobles HTTP, no nube real. Analisis de cuatro archivos sin incidencias; dart format y git diff --check correctos. No cambios de API ni contratos. Aceptacion visual humana pendiente. Validador SDD global conserva enlaces historicos rotos ya documentados.
