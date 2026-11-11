# 055 — Revisión visual por pantalla y navegación única
## 1. Contexto
Captura del usuario: Mi perfil duplica barra inferior y texto aparece demasiado fino. La referencia es https://nexo-local-v1.netlify.app/ recorrida en Chrome.
## 2. Objetivo
Corregir diferencias observables por pantalla y no declarar paridad completa solo por componentes compartidos.
## 3. Alcance
- FR-001: una barra inferior visible en cada ruta principal/detalle; navegación de perfil y edición en navegador raíz.
- FR-002: pesos estáticos explícitos de fuentes de referencia en todas las pantallas.
- FR-003: ajustar portada/avatar, encabezados, lista de prestadores, compositores y mensajes según reglas finales observadas.
- FR-004: mantener cabeceras relevantes al desplazar Inicio/Buscar y selector de ubicación como hoja donde corresponde.
- NFR-001: conservar datos reales, correo verificado, formularios y movimientos reducidos; no inventar contenido pendiente.
## 4. Contratos
Sin nuevos endpoints ni datos demo implícitos. Se conserva 054.
## 5. Criterios
AC-001: ruta Cuenta → Mi perfil → editar/volver/navegar tiene una sola barra y acciones visibles.
AC-002: comparación visual de capturas con fuentes cargadas, sin errores de layout a 390 y 320 px.
## 6. Verificación
Pruebas actuales unit/integration/security, analizador, APK e inspección en Android. Auditoría en docs/revision-visual-pantallas.md registra diferencias aplicadas y límites.
## 7. Entrega
Sin publicación ni firma humana.
## Aprobación
Estado: Borrador documental; corrección autorizada, aceptación humana pendiente.
