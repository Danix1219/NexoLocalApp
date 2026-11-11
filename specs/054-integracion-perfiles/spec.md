# 054 — Integración de perfiles reales
## 1. Contexto
Backend grupo 03 ya dispone de cinco operaciones. Autoridad: NexoLocalApi/specs/endpoints/03-perfil-prestador/implementacion.md. nv-06 parcial.
## 2. Objetivo
Conectar alta, propio/público, edición por sección y comparación sin éxitos simulados.
## 3. Alcance
- FR-001: cliente perfil siempre remoto salvo fake explícito; solo provider.not_found equivale a ausencia.
- FR-002: cuerpos por sección, slugs y ubicación propia.
- FR-003: importes exactos, términos y política de completitud.
- NFR-001: no persistir perfiles privados en caché ni sustituir fallos por demo. Fotos pendientes de infraestructura.
## 4. Plan
NexoApi/HttpNexoApi, models, provider_contract, onboarding y edit_sheets. Preservar Riverpod, rutas, UI de referencia y reintentos idempotentes.
## 5. Contratos
POST providers, GET providers/me y providers/{id}, PATCH providers/me/{section}, GET providers/compare. No acceso directo a bases; no crear endpoints.
## 6. Criterios
AC-001 FR-001/NFR-001: pruebas de error real, ausencia tipada y privacidad. AC-002 FR-002/003: transporte/modelos/widgets con cuerpos válidos, slugs y centavos sin pérdida.
## 7. Evidencia
checklist y docs/integracion-perfiles.md distinguen adaptador en memoria, backend aislado y dispositivo.
## Aprobación
Estado: Borrador documental; construcción local autorizada, sin firma humana.
