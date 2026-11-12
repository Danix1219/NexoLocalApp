# Ubicación real, correo de marca y confirmación de alta — 056

## Resultado
Registro y app comparten un selector con búsqueda explícita de calle/colonia/ciudad, resultados reales, mapa, GPS, radio y confirmación. El centro inicial es solo una vista: no se asigna al usuario ni permite confirmar sin elegir. Búsqueda e inversa pasan por Discovery a Photon/OpenStreetMap. Los nombres son aproximados y dependen de los datos disponibles; nunca certifican un domicilio.

Cuenta y Buscar restauran la selección del servidor con etiqueta/radio/coordenadas, conservan una última selección real segura por cuenta y limpian el estado al cambiar de usuario. Las consultas no usan el fallback demo ni la caché SQLite genérica; errores se muestran y el mapa sigue disponible. La UI informa del proveedor y muestra atribución.

La confirmación de cuenta creada permanece hasta que el usuario continúa. Si falla el login posterior, muestra éxito del alta e invita a iniciar sesión; si falla guardar ubicación, mantiene el alta y permite reintentar sin crear la cuenta otra vez. La zona escogida se muestra inmediatamente. Sin registro real nuevo para ejecutar pruebas.

Buscar usa fondo blanco, espaciados/campos y filtros de la maqueta, conserva navegación única y estado de filtros. No se agregan prestadores demo: el listado real continúa pendiente del bloque backend correspondiente.

El correo SMTP ahora contiene HTML y texto alternativo con colores Nexo, código destacado, seguridad y vencimiento local. Autoridad y pruebas en backend specs/endpoints/04-descubrimiento/geocodificacion.md. Vista previa local: C:/Users/kevin/nexolocal_api/artifacts/email-preview.html. El próximo código solicitado usa esta plantilla; no se envió uno para probar.

## Verificación
- 250 pruebas Flutter completas con cobertura. Archivo existente diseno_maqueta_test.dart ampliado a 19 pruebas, incluyendo confirmación con/sin sesión, búsqueda/selección/error y restauración aislada entre cuentas. HTTP y privacidad ampliados en sus capas actuales.
- Después de excluir lugares/ubicación de SQLite se repitieron caché e íntegramente seguridad: 55 pruebas aprobadas. Sin archivo nuevo de pruebas, sin nuevos jobs de CI.
- Analizador: cero errores y warnings, 13 infos previos. APK debug live apuntando a http://127.0.0.1:5188; instalación final por adb install -r: Success; arranque Android: Status ok (2026-11-10). Se conservaron los datos de la aplicación. La pantalla observada fue la bienvenida sin sesión activa; restauración autenticada pendiente de iniciar sesión.
- Photon real: Tula de Allende devuelve su zona y coordenadas; inversa devuelve Tula, Hidalgo. Es una consulta pública, no prueba de GPS físico ni datos del usuario.

## Límites
Photon público admite uso moderado y no ofrece SLA; producción de volumen requiere instancia/proveedor apropiado. Fuente: https://github.com/komoot/photon/blob/master/README.md y docs/api-v1.md. No se usa Nominatim público como autocompletado. Sin claves nuevas ni infraestructura cloud.

GPS físico con permisos concedidos, aceptación visual de todos los estados, entrega/render Gmail real y alta de una cuenta real nueva quedan para comprobación interactiva. Fotos/Blob/moderación y búsqueda de prestadores siguen pendientes. No se publicaron cambios ni se ejecutó Terraform.

- Regresión posterior al ajuste de autenticación: 28 pruebas de interfaces y HTTP aprobadas. GET de ubicación exige autenticación; búsqueda/inversa públicas funcionan durante el registro.
