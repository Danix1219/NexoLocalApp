# 053 — Paridad visual con la maqueta desplegada

## 1. Contexto
Referencia examinada en Chrome: https://nexo-local-v1.netlify.app/ (2026-11-09). Conservamos Flutter/Riverpod/Dio y correo real.
## 2. Objetivo
Corregir divergencias observadas de componentes, perfil personal y movimiento compartido.
## 3. Alcance
Componentes compartidos aplicables a acceso, registro, Inicio, Buscar, Publicar, Cuenta, perfiles, solicitudes, pedidos, mensajes y hojas. No activar endpoints pendientes ni copiar la autenticacion SMS o los contadores demo.
## 4. Requisitos
- FR-001: Entrada de pantalla 220ms ease-out, opacidad .4 a 1 y desplazamiento 8px.
- FR-002: Pulsacion .98 durante 140ms y respeto a movimiento reducido sin perder foco o acciones.
- FR-003: Barra inferior con icono 21px en area 38x30, fondo solo en icono activo, texto activo 800 y badge real.
- FR-004: Mi perfil con portada, avatar superpuesto, identidad, estadisticas reales o pendientes, acciones y pestañas.
- FR-005: Subpantallas de perfil, guardados, comparacion, interesados y pedido mantienen acceso a navegacion; chat/mapa/formularios quedan sin barra.
- NFR-001: Cambiar pestañas conserva borradores y posicion; no animar errores como si fueran datos nuevos.
## 5. Contratos
Sin cambios API. Correo verificado sustituye el celular confirmado del prototipo. Fotos y experiencias pendientes se anuncian sin simular guardado.
## 6. Criterios
AC-001: widgets verifican pulsacion, cancelacion, movimiento reducido y estado persistente (FR-001/002, NFR-001).
AC-002: pruebas verifican barra y perfil sin contadores inventados (FR-003/004/005).
## 7. Evidencia y limites
Recorridos observados y diferencias detalladas en docs/paridad-visual-maqueta.md. Revision visual en telefono pendiente hasta instalar APK. No se afirma haber probado cada combinacion de estados de la maqueta.
## Aprobacion
Estado: Borrador documental; implementacion local con evidencia registrada por separado, sin firma humana.
