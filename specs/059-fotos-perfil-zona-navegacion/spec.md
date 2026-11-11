# 059 Fotos de perfil, zona y navegación

Estado: implementado localmente; validación física pendiente.

FR-001: avatar y portada muestran una animación skeleton sobre la foto elegida mientras Azure valida; el indicador permanece en el elemento correcto y al fallar se conserva la foto anterior.
FR-002: el alta profesional permite foto y portada; obliga a elegir una zona real. El perfil profesional permite ver y cambiar ambas fotos.
FR-003: la zona pública del prestador usa la localidad real del punto elegido, recupera la selección guardada cuando coincide con el punto y mantiene difuminado el punto residencial.
FR-004: tocar nombre o foto del autor abre el perfil correspondiente usando datos públicos reales. El retroceso desde una pestaña raíz secundaria vuelve a Inicio.
NFR-001: miniaturas para avatares y caché privada breve de medios; no exponer ubicación exacta residencial ni SAS.

AC-001: indicador de revisión en avatar/portada y foto anterior intacta ante error.
AC-002: alta profesional con foto/portada y zona elegida, sin punto predeterminado ficticio.
AC-003: perfil público desde publicación y retroceso de pestaña sin salida accidental.
AC-004: pruebas Flutter/.NET y compilación APK con API local documentadas; aceptación humana pendiente.

Refinamiento visual: el avatar se previsualiza circular, la portada conserva su formato horizontal y la selección de ubicación profesional se guarda también para recuperar su etiqueta pública. La publicación muestra una confirmación con acceso a la entrada creada.
