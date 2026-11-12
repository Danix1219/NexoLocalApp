# 054 — Integración de perfiles reales

Estado: Borrador documental; construcción local registrada; aceptación humana pendiente.

## 1. Contexto y alcance
Conectar alta, consulta de perfil propio/público, edición por sección y comparación a las operaciones reales disponibles del grupo 03.

## 2. Actores y precondiciones
Persona autenticada para alta, edición y consulta de perfil propio. Perfil público y comparación respetan permisos y campos visibles; se conserva la distinción entre ausencia real y error del servidor.

## 3. Requisitos funcionales
- FR-001: el cliente de perfil usa backend real salvo modo fake explícito; solo `provider.not_found` representa ausencia de perfil.
- FR-002: la edición envía cuerpos por sección, slugs de catálogo y ubicación propia con el contrato vigente.
- FR-003: importes, términos y política de completitud se preservan sin pérdida de precisión.

## 4. Requisitos no funcionales y datos
- NFR-001: perfiles privados no se persisten en caché y los fallos nunca se reemplazan por datos de demostración; fotos quedan sujetas a la infraestructura disponible.

## 5. Frontera y decisiones
Operaciones consumidas: POST providers, GET providers/me, GET providers/{id}, PATCH providers/me/{section} y GET providers/compare. Autoridad: [catálogo backend](../../../API_NexoLocal/docs/endpoints.md) y [fichas de operación](../../../API_NexoLocal/docs/contracts/fichas-operaciones.md). Sin acceso directo a bases de datos ni endpoints nuevos.

## 6. Aceptación local
- AC-001 → FR-001/NFR-001: pruebas distinguen error real de ausencia tipada y verifican privacidad.
- AC-002 → FR-002/FR-003: transporte, modelos y widgets conservan cuerpos válidos, slugs e importes exactos.
- AC-003 → FR-001/FR-002/FR-003/NFR-001: suites, APK y evidencia real se documentan por separado de la aceptación humana.

## 7. Trazabilidad y límites
| Requisito | Tareas | Criterios |
|---|---|---|
| FR-001 | T-001,T-003 | AC-001,AC-003 |
| FR-002 | T-002,T-003 | AC-002,AC-003 |
| FR-003 | T-002,T-003 | AC-002,AC-003 |
| NFR-001 | T-001,T-003 | AC-001,AC-003 |

## Aprobación
Construcción local registrada; no hay firma humana de aceptación.
