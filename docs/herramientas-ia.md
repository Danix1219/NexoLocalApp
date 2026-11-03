# Codex y Claude Code en la app

Las herramientas activas son Codex y Claude Code. Se elimina la carpeta de la herramienta descartada; no se reutilizan perfiles o comandos incompatibles.

| Herramienta | Entrada | Reglas a leer |
|---|---|---|
| Codex | [AGENTS.md](../AGENTS.md) | Constitucion, Memoria y spec/plan/tasks/checklist del incremento |
| Claude Code | [CLAUDE.md](../CLAUDE.md) | Remite a AGENTS y a las mismas autoridades; sin otra constitucion |

[Procedimiento comun API/app](../../docs_nexo/SDD_HERRAMIENTAS_IA.md). Primera spec movil: [001-base-flutter](../specs/001-base-flutter/spec.md). La app conserva su flujo movil y Flutter; no hereda carpetas ni capas de proyectos .NET.

Antes de editar: identificar spec/tarea, archivos permitidos, estado, entradas del contrato y pendientes. Trabajar secuencialmente y registrar la herramienta que SI intervino y validacion real. Al traspasar, entregar archivos cambiados, fuentes/decisiones, comprobaciones y deuda; el receptor vuelve a leer las autoridades. No habilitar subagentes, instalaciones, red o permisos por una tabla de roles.

La API conserva la autoridad de contratos y autorizacion del servidor; la app registra consumo, pantallas, permisos, estado local/offline y evidencia de dispositivo cuando exista. Flutter no accede directamente a MongoDB/Neo4j. No confundir pruebas con dobles o lint documental con integracion real.

AGENTS y CLAUDE son las entradas de este proyecto. No se crean carpetas .codex/.claude vacias ni configuraciones supuestas para sustituir un README antiguo. Configuracion adicional requiere necesidad real y verificar compatibilidad del cliente. La presencia de instrucciones no demuestra que se hayan cargado ni que haya skills instaladas.

Mantener reglas permanentes en sus autoridades y Memoria como registro historico. Las referencias historicas del material docente o inventario de publicacion no son configuracion activa; no se reescribe su evidencia.
