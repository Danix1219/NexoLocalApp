# Plan
NexoApi/HttpNexoApi/HybridNexoApi → Riverpod → compositores, solicitudes, perfil y mapa existentes. Entrada: backend grupos 01–06. Catálogo real; listas recorren cursores secuencialmente sin perder registros ni aceptar bucles. Pruebas extendidas en las tres capas actuales, sin archivos nuevos de test ni jobs/Terraform. Medios y grupos aún ausentes conservan Próximamente; fake solo explícito para grupos ya publicados. Sin secretos ni publicación.

Ajuste solicitado 2026-11-10: filas de Publicar con columnas estables, valores a la izquierda de su columna y flechas fijas; pruebas a 320/390px. Error 503 de moderación se explica en el contexto de publicación, conserva borrador y no fabrica aprobación. Content Safety exige endpoint y clave reales.

Incremento de medios autorizado: upload espera approved por polling acotado; no usa imagen processing. Fotos reales en cuenta, Mi perfil, portada personal/profesional, alta profesional y trabajos/solicitudes. No fake automático para imágenes, sin claves en Flutter.

Ajuste FR-004: componente de texto extensible en tarjetas existentes; medir desbordamiento por ancho real y escala de texto, reiniciar estado cuando cambia el contenido. API entrega description completo junto al excerpt compatible.
