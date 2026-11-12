# Revisión visual de pantallas — 055

Referencia examinada en Chrome: [maqueta](https://nexo-local-v1.netlify.app/). Esta revisión corrige diferencias que quedaron en 053; sus afirmaciones de alcance no sustituyen la evidencia de este documento. Contratos de perfiles: se conserva 054.

## Causas corregidas

Mi perfil se abría con Navigator.push dentro de una rama del shell. El shell y el perfil pintaban cada uno una barra. Ahora /my-profile pertenece al navegador raíz y la edición usa una hoja raíz. El regreso mantiene la pestaña Cuenta.

Nunito Sans tenía un archivo variable cuyo eje wght inicial era 200, registrado sin pesos explícitos. Se generaron caras estáticas 400/500/600/700/800 de los archivos locales existentes de Nunito Sans y Plus Jakarta Sans. pubspec declara cada peso; se conservan licencias. Este cambio necesita reconstrucción y reinstalación: hot reload no recarga fuentes empaquetadas.

## Revisión por recorrido

| Pantalla / recorrido | Ajuste aplicado y comportamiento conservado |
|---|---|
| Bienvenida, login, recuperación, código y registro | Fuentes reales con pesos explícitos; se conservan estructura de formularios, iconos de paso, campos redondeados y pie fijo ya coincidentes. La decisión real de correo/SMTP sustituye los textos SMS de la referencia. Sin cuentas demo en producción. |
| Inicio solicitante: Para ti / Mis solicitudes | Solo cabecera superior fija; buscador y selector se desplazan con el contenido. Feed sin tarjeta exterior redondeada: ancho completo, foto cuadrada, separador y contacto verde con texto blanco. Solicitudes conservan tarjeta redondeada con margen y espaciados ajustados. |
| Inicio prestador: Comunidad / Oportunidades | Misma cabecera fija y componentes de feed/solicitudes corregidos. Se mantienen pedidos, filtros y estados reales. |
| Buscar solicitante | Título fijo. Se retiran la franja añadida de categorías y el selector Lista/Mapa que no aparecen en este recorrido de la maqueta. Se conservan sugerencias y filtros; las categorías siguen disponibles en filtros. Resultados con avatar 54, título Jakarta 16, recomendaciones como texto y proporción Comparar/Contactar 1:1.4. |
| Buscar prestador | Cabecera fija y fuentes corregidas; se conserva su mapa de oportunidades, sin confundirlo con el recorrido del solicitante. |
| Perfil solicitante | Una barra inferior, avatar 88, cámara circular verde con borde blanco, portada con acción blanca en píldora, nombre 23, cifras y pestañas. Ver perfil abre la vista y editar queda separado. Correo verificado y actividad real o raya. |
| Perfil prestador: trabajos, información y opiniones | Avatar 88, nombre 23 y pestañas 54/15 con indicador de 3 px. Fuentes y feed de trabajos corregidos. Se conservan llamadas a API, privacidad, precios, horario y edición por sección. |
| Publicar: solicitud, experiencia y trabajo | Cabecera Publicar fija en los tres compositores, pesos de texto y título principal 22. Se conserva contenido, selección de servicio, opciones y borradores. |
| Mensajes y conversación | Cabecera fija en inbox y fuentes correctas en filas y burbujas. Se conserva el tratamiento anterior de mensajes/entrada de burbujas y movimiento reducido. No se simula una conversación real para rellenar la interfaz. |
| Cuenta | Título fijo, tarjeta Ver perfil, fuentes y hojas raíz; el nombre no abre directamente edición. Se conservan cambio de modo y datos de ubicación/cuenta. |
| Ubicación: alta, cuenta, búsqueda, solicitudes y perfil profesional | Ruta presentada como hoja de 86%, esquinas superiores 28, fondo oscurecido, asa, título y cierre. Transición vertical 240/180 ms, omitida con movimiento reducido. Se mantiene mapa/GPS/radio y el resultado al confirmar o cancelar. |
| Interesados | Resumen en tarjeta 18 con margen 12, título 19 y tarjetas de interesados 18 sin sombra. Fuentes, cabecera y barra comunes; se conserva información de negocio y acciones autorizadas. |
| Guardados, comparación y detalle de pedido | Se aplican fuentes y subcabeceras comunes. Guardados reutiliza las tarjetas de prestador y trabajos corregidas. Se conservan tabla, etapas, privacidad y botones con datos del contrato. |
| Alta de prestador y hojas de edición/contacto/filtros/reporte | Pesos correctos, componentes de botones/campos existentes y presentación de hojas sobre el navegador raíz. Se conserva secuencia y validación de cada formulario. No se envían reportes ni se modifica una cuenta para demostrar el diseño. |

## Pruebas de regresión

Se amplía el archivo existente test/unit/diseno_maqueta_test.dart, sin crear un job de CI adicional: carga de las diez fuentes, recorrido con router real Cuenta → Mi perfil → edición → regreso, menú único a 320 y 390 px, cancelación del selector, foto cuadrada a ancho completo y cabecera fija. Se conservan las pruebas anteriores de pulsación cancelable, deshabilitados, borrador, movimiento reducido y contratos. Los dobles de pruebas no acreditan servicios cloud.

## Límites explícitos

Las pantallas con endpoints pendientes muestran Próximamente. Fotos/portada siguen pendientes de Blob y moderación. El selector funciona con mapa y GPS; búsqueda por dirección y geocodificación de colonias siguen pendientes y no se dibujan resultados ficticios. La referencia muestra publicaciones demo que no se trasladan a la cuenta real.

Las reglas visuales observadas se aplican en los recorridos descritos; no hay certificación automática píxel a píxel de cada estado ni aprobación humana de todas las combinaciones. Las pruebas a 320/390 verifican layout y navegación; no equivalen a capturas físicas de ambos anchos. No se publican cambios ni se ejecuta Terraform.

## Evidencia final

- Suite completa: `flutter test --coverage --reporter expanded`, 242 pruebas aprobadas. Después del último ajuste de radio/sombra de ProviderRow se repitió el archivo visual: 14 pruebas aprobadas. El único cambio posterior fue convertir una decoración constante en const.
- Análisis final: `flutter analyze --no-fatal-infos`, sin errores ni warnings; 13 infos previos. Compilación debug live con API_BASE_URL=http://127.0.0.1:5188 aprobada.
- Instalación en Android conectado: `adb install -r` Success, datos conservados, reverse USB 5188. El primer am start -W agotó la espera de arranque; la comprobación posterior devolvió Status: ok y se observó la app renderizada. No se atribuye el primer timeout a una prueba aprobada.
- Capturas físicas inspeccionadas de Inicio, Cuenta y Buscar: fuentes cargadas y navegación única. El usuario abrió Mi perfil; su árbol accesible contiene Volver, Mi perfil, Editar mi perfil y una sola instancia de cada destino Inicio/Buscar/Publicar/Mensajes/Cuenta. Evidencia local en el workspace backend artifacts/visual055-profile-ui.xml. El usuario cambió de pestaña durante la captura, por lo que no se presenta una captura de Buscar como si fuera Mi perfil.
- Android rechaza toques por adb con SecurityException/INJECT_EVENTS; no se cambiaron permisos del teléfono. La navegación física a Mi perfil la realizó el usuario, y la regresión automática del recorrido se verifica con el router real en widgets.
- `python tools/ci/revisar_workflows.py`: WORKFLOWS-OK. `git diff --check`: sin errores. Sin archivo nuevo de pruebas, no cambia el inventario de jobs.
- `scripts/check_sdd.ps1` conserva enlaces históricos rotos a API_NexoLocal/docs_nexo; no se declara SDD-OK. No aparecen fallos propios de 055. La aceptación visual humana de todas las pantallas y servicios pendientes sigue abierta.

