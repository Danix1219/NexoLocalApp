# Auditoria de interfaces en dispositivos - 2026-11-21

## Metodo y alcance real
Recorrido asistido y automatizado mediante ventanas scrcpy oficiales, controladas por Computer Use, con observacion despues de cada accion. No es una suite Android de extremo a extremo desatendida ni cobertura de todas las rutas. No se enviaron publicaciones, mensajes ni adjuntos; no se cambiaron modos ni permisos. Abrir la conversacion genero el acuse de lectura propio de la app. Sin credenciales ni contenido privado en este informe.

Motorola moto g34 5G Android 14: recorrido de prestador con datos reales. Xiaomi Redmi 2201116SG Android 12: bandeja y Cuenta cliente observadas, control/captura congelados. Usuario confirma navegacion fisica correcta; no atribuir el bloqueo del espejo a Nexo. Se probaron transporte forward, decodificacion software y codificador Android alternativo sin lograr seguimiento fiable. No se concluye equivalencia visual entre telefonos.

## Cobertura observada
| Pantalla/estado | Resultado |
|---|---|
| Inicio prestador / oportunidades | Tarjeta con autor, fotos y navegacion visibles. No recorrido completo del feed. |
| Buscar solicitudes / lista | Fallo: titulo partido en tres lineas, ultima letra aislada por ubicacion lateral. |
| Filtros solicitudes | Panel completo y cierre; no se aplicaron filtros. |
| Buscar solicitudes / mapa | Mapa y marcadores cargaron; no recorrido de todos los marcadores. |
| Publicar trabajo / vacio y teclado | Sin overflow visible; ayuda comprimida a la derecha de Agregar fotos. No se publico ni seleccionaron archivos. |
| Cuenta prestador y scroll | Tarjetas, mapa, progreso, disponibilidad y accesos visibles. No cambios de permisos/modo. |
| Perfil propio prestador | Cabecera, portada, indicadores y acceso al visor visibles. Compartir copia enlace: etiqueta poco explicita. |
| Visor de avatar y QR | Contenido completo, acciones y tarjeta QR visibles; no se escaneo el QR en este recorrido. |
| Mensajes / pendiente | Al abrir chat y volver, desaparecieron contador y etiqueta de pendiente. Un caso, no prueba de concurrencia. |
| Chat / historico y apariencia | Entrada al extremo reciente, texto, fotos y voz visibles, cinco estilos y seleccion visibles. No nuevos envios/reproduccion/grabacion ni edicion/borrado. |
| Guardados / solicitud | Tarjeta y scroll correctos; autor sin nombre y avatar interrogacion, mientras Inicio muestra autor para la misma solicitud. |
| Xiaomi Cuenta cliente y bandeja | Observacion parcial; captura congelada impide afirmar recorrido. |

## Hallazgos priorizados
1. UI-01 Alta: titulo Buscar solicitudes ilegible. Correccion: separar ubicacion en segunda fila, tambien para busqueda cliente; regresion de encabezado a 320/390 y escala 1.3.
2. UI-02 Media: ayuda de Publicar comprimida en varias lineas junto al boton. Correccion: debajo del boton, ancho disponible y alineacion inicial.
3. DATA-01 Media, pendiente: Guardados carece de autor. Codigo confirma que MongoSavedStore permite campos de solicitud sin client y Flutter usa client.displayName/photoUrl. Requiere conciliacion con proyeccion publica actual; no copiar datos privados ni inventar identidad. No corregido en este incremento visual.
4. UX-01 Baja, propuesta: Compartir del perfil propio copia enlace. Diferenciar Copiar enlace y Compartir como el visor; no se cambio el contrato de esa accion.
5. UX-02 Baja, propuesta: etiquetas peque?as y baja diferenciacion de metadatos en bandeja/QR; medir contraste y tamanos antes de ajustar. No se declara incumplimiento medido.

## Pendientes de cobertura
Cliente Inicio/Buscar/Publicar/perfil; detalle prestador ajeno, comparador, solicitud/autor/interesados, pedidos, ubicacion y formularios secundarios; inicio/registro/recuperacion sin cerrar sesiones existentes; errores/offline, permisos, orientacion, accesibilidad TalkBack y escalas grandes, fotografia/voz/envios. Repetir UI-01/UI-02 con APK nuevo en dispositivos. Escaneo QR y navegacion deep-link no verificados aqui. No aceptacion productiva ni de rendimiento.

## Ajuste adicional detectado por regresion
ChatLive dejaba Future.delayed de reconexion pendiente al cerrar el chat. Se sustituyo por Timer cancelable al detener o reiniciar. Se conserva renovacion de ticket y chequeo de generacion. El primer intento de suite detecto este fallo y un error en la comprobacion de lineas del test; no se presenta ese intento como aprobado. Resultado final se registra al terminar.

Regresion final: diseno_maqueta_test.dart 54/54 aprobadas (incluye 320/390 px con texto 1.3). Analisis completo detecto solo prefer_const_constructors en test nuevo; corregido. Los ajustes nuevos no se han instalado ni vuelto a observar en telefonos.
Analisis final focalizado de los cinco archivos modificados: sin incidencias (20.4 s).

## Ajustes aplicados a partir del informe
- UI-01/UI-02: conservados encabezado de busqueda con ubicacion en segunda fila y ayuda de Publicar debajo del boton de fotos.
- DATA-01: mitigacion visual en RequestCard (incluye Guardados): sin nombre publico, mostrar Solicitud de la comunidad y simbolo de persona en vez de interrogacion y nombre vacio. Datos de ubicacion/fecha solo se separan cuando existen. No se inventa nombre ni se recupera una foto de otra cuenta. La proyeccion backend que omite client sigue pendiente; no declarar la identidad recuperada.
- UX-01: ambas variantes del perfil prestador abren una hoja con Compartir, Copiar enlace y Ver codigo QR. Compartir invoca el selector nativo; copiar confirma la copia; QR reutiliza tarjeta existente y enlace validado. Abrir o cancelar el menu no transmite datos. Fallos del canal muestran alternativa de copiar.
- UX-02: fecha de bandeja a 13 con ancho flexible y elipsis para preservar el nombre. Contador minimo 24 sin alto fijo para respetar escala de texto. No se afirma medicion de contraste ni cumplimiento TalkBack a partir de estos cambios.

Validacion de estos ajustes: diseno_maqueta_test.dart 56/56 aprobadas, incluida tarjeta sin autor y apertura del menu/QR sin invocar compartir. Falta nueva observacion fisica con APK actualizado; captura Xiaomi sigue siendo una limitacion de la herramienta. Sin cambios de API, nuevas dependencias ni datos persistidos.

Cierre ajustes UI: 56/56 pruebas de diseno aprobadas; analisis focalizado sin incidencias. APK debug/live generado e instalado con install -r en Xiaomi y Motorola, ambos abiertos; puertos 5188/10000 reversados. No equivale a validacion visual posterior. Validador documental ejecutado: 453 observaciones (incluye tareas/fase y enlaces), no SDD global aprobado.
