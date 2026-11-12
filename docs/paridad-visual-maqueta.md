# Paridad visual con la maqueta — incremento local

Referencia: [Nexo Local Prototipo](https://nexo-local-v1.netlify.app/), recorrida en Chrome el 2026-11-09. Spec rectora: [053](../specs/053-paridad-visual-maqueta/spec.md). Este registro distingue observación del prototipo, implementación Flutter y validación local; no constituye aprobación humana.

## Recorridos observados

| Recorrido en Chrome | Resultado aplicado o conservado en Flutter |
|---|---|
| Bienvenida, explorar sin cuenta y guía inicial | Se conserva la bienvenida existente: al revisar las reglas CSS finales coincidían sus tamaños y secuencias. Transición compartida al entrar en pantallas. |
| Acceso demo de solicitante y prestador | Se usa únicamente para examinar el prototipo. La app conserva acceso real, verificación por correo y celular declarado. |
| Inicio: Comunidad y Oportunidades | Se conservan compositores y estados actuales; botones de actividad incorporan respuesta de pulsación. No se copian publicaciones, pedidos ni cifras demo. |
| Buscar, filtros, comparación de dos prestadores | Barra inferior compartida, estilos activos y acceso desde comparación. Filtros existentes conservan sus acciones. |
| Ubicación desde Buscar | Se observan mapa, radio, búsqueda y acciones de GPS en el prototipo. La app conserva selección real en mapa, radios y permisos. Diferencias pendientes: selector Flutter en página, búsqueda/geocodificación de direcciones y nombres de colonias. No se inventa un resultado de búsqueda. |
| Perfil de prestador: trabajos, información y opiniones | Portada de 166 px, navegación inferior y animación de pestañas. El perfil propio selecciona Cuenta. Insignias explican correo verificado, sin trasladar la afirmación SMS de la maqueta. |
| Foto de trabajo y reporte de perfil | Se abrieron galería y formulario de motivos en Chrome sin enviar reporte. Hojas existentes reciben duración compartida y movimiento reducido; no se crea una operación nueva de API. |
| Publicar solicitud, experiencia y trabajo | Se revisan compositores y opciones por rol. Se conserva lógica de formularios y borradores. No se afirma haber enviado cada variante. |
| Mensajes, conversación y pedir servicio | Entrada de burbujas de 180 ms y desplazamiento de 6 px; IDs estables evitan reanimarlas en cada consulta. Desplazamiento del chat respeta movimiento reducido. |
| Detalle de pedido pendiente | Se observa etapa, ubicación aproximada y privacidad de dirección. La navegación inferior permanece accesible; no se simula aceptar o resolver un pedido real. |
| Cuenta, guardados y Mi perfil solicitante | Página propia con portada, avatar superpuesto, nombre, ubicación, correo, acciones y pestañas. Editar es una acción separada. Contadores reales o raya cuando el servicio está pendiente. |
| Alta de prestador: tipo, experiencia, oficio y ubicación | Se observaron pasos sin publicar cuenta demo. Se conservan contratos y formularios existentes; no hay aceptación de todas sus combinaciones. |

## Componentes y movimiento

- Fuentes Plus Jakarta Sans y Nunito Sans incluidas en assets con sus licencias OFL, sin descargas de fuentes en ejecución.
- Entrada compartida: 220 ms ease-out, opacidad 0.4 a 1 y desplazamiento vertical de 8 px. Cambiar pestaña no reemplaza el estado de sus formularios.
- Pulsación: escala 0.98 durante 140 ms, cancelable y sin acción adicional. Botones deshabilitados no se comprimen.
- Barra: icono de 21 px dentro de área 38 × 30, fondo únicamente en icono activo, etiqueta activa de peso 800. El contador del shell procede del inbox; las barras de detalle no muestran un contador inventado.
- Hojas: apertura/cierre de 220 ms, accesibilidad y desplazamiento nativos de Flutter. No se afirma equivalencia exacta entre la física nativa de la hoja y la animación CSS.
- Avisos: duración 2.6 s y animación de 200 ms. Entradas, pulsaciones y desplazamientos adaptados a movimiento reducido.

## Validación ejecutada

- `flutter analyze --no-pub --no-fatal-infos`: 0 errores, 0 warnings; 13 observaciones informativas pendientes.
- `flutter test --no-pub --coverage --reporter expanded`: 225 pruebas aprobadas entre unitarias, integración y seguridad.
- Siete pruebas nuevas en `test/unit/diseno_maqueta_test.dart`: pulsación/cancelación, deshabilitado, movimiento reducido, conservación del borrador, navegación estrecha y acciones, perfil sin contadores ficticios y edición separada. Se amplió `models_test.dart` para distinguir verificación de correo y celular.
- `python tools/ci/generar_pipeline.py`: pipeline y lista de 54 checks requeridos regenerados. Sin Terraform apply ni ejecución de CI remota.
- `git diff --check`: aprobado. `python tools/ci/revisar_workflows.py`: WORKFLOWS-OK. El validador SDD conserva errores de enlaces históricos a carpetas hermanas; no se presenta como SDD-OK.

## Límites de aceptación

No hay comparación automatizada píxel a píxel ni aceptación humana de todas las pantallas, tamaños, errores y combinaciones de estados. La navegación revisada en Chrome no acredita un recorrido completo con datos reales en Android. Fotos/portadas siguen Próximamente hasta configurar almacenamiento y moderación. Los módulos sin endpoint muestran Próximamente; errores de autenticación, red y negocio conservan su tratamiento. Geocodificación, Firebase y demás servicios pendientes no se habilitan por este ajuste visual.

APK debug compilado con API_MODE=live y API_BASE_URL=http://127.0.0.1:5188. Instalación de este incremento pendiente: adb devices no detecta teléfono conectado en la comprobación actual. La instalación de un incremento anterior no acredita este APK. Ningún commit, push o publicación se realiza en este incremento.
