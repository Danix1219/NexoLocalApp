# 056 — Correo, ubicación real, registro y Buscar
## Requisitos
FR-001: integrar Photon mediante endpoints Discovery para búsqueda explícita, nombre de zona real, mapa/GPS y confirmación; sin fallback demo.
FR-002: restaurar punto/radio/etiqueta propios desde servidor y caché por cuenta; visualizar y cambiar en Cuenta, Buscar y registro. Sin atribuir al usuario el centro inicial del mapa.
FR-003: mostrar confirmación de cuenta creada tanto con sesión como si falla el login posterior. Nunca repetir el alta para un error de ubicación. Mantener pantalla hasta acción del usuario.
FR-004: Buscar usa el fondo, espaciados, campo/botón 50 y cabecera de maqueta; resultados reales o estado pendiente sin lista demo.
NFR-001: privacidad, errores visibles, atribución OpenStreetMap/Photon, cancelación de respuestas obsoletas y límites. Mantener movimiento reducido.
## Aceptación
AC-001: búsqueda, selección y cancelación probadas con dobles; prueba externa no personal diferenciada.
AC-002: restauración y aislamiento por cuenta, error de ubicación y éxito de alta no omitido.
AC-003: regresiones de diseño y suites actuales aprobadas; no equivale a aceptación humana total.
Autoridad API: backend specs/endpoints/04-descubrimiento/geocodificacion.md. HTML email pertenece al backend.
