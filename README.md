# App_NexoLocal · SDD

Patrón de referencia: WebSDD. Flujo: `specs/NNN-slug/spec.md → plan.md → tasks.md → checklist.md`. Estructura adoptada para documentación; todas las specs son borradores, no releases existentes.

## Orden de lectura

1. Constitución: [constitution.md](constitution.md).
2. [AGENTS.md](AGENTS.md): cómo trabajar.
3. [Memoria.md](Memoria.md): estado y deuda reales.
4. [Índice de specs](specs/README.md): fase actual y dependencias.
5. [CHECKLIST_PR.md](CHECKLIST_PR.md) y docs vivos del cambio.

## Carpetas presentes

`specs/`: qué hacer, cómo, tareas y comprobación. `docs/`: referencias vivas. `scripts/check_sdd.ps1`: validación documental. [AGENTS.md](AGENTS.md): entrada y procedimiento comun para Codex; [CLAUDE.md](CLAUDE.md): entrada de Claude Code, que remite a las mismas reglas. `specs/templates/`: plantillas del formato de WebSDD.

## Validación disponible ahora

Desde esta carpeta: `powershell -NoProfile -File scripts/check_sdd.ps1`.

Solo verifica estructura, enlaces de fases y trazabilidad documental. No ejecuta build, APIs, Flutter, tests o CI. No existen todavía proyectos compilables. Los comandos de compilación/seguridad del profesor se configurarán al implementar nv-01/nv-03 o 001/002.

## Adaptación del producto

Este contexto prepara Flutter; WebSDD aporta organización y ciclo, no Razor, cookies de navegador ni Bootstrap. La landing no se transforma en la app móvil.

Ver [diferencias justificadas](../requerimientos_nexolocal/docs/REFERENCIA_PROFESOR.md). Soporte compartido: [arquitectura](../requerimientos_nexolocal/sdd/architecture/README.md), [permisos](../requerimientos_nexolocal/sdd/architecture/estados-y-permisos.md), [decisiones propuestas](../requerimientos_nexolocal/sdd/governance/decisiones.md).

## Redefinición documental 0.2.0

Lectura coordinada: [acuerdo de trabajo](../docs_nexo/SDD_ALINEACION.md), [cobertura y brechas](../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md), [Codex y Claude Code](../docs_nexo/SDD_HERRAMIENTAS_IA.md) y [skills seleccionadas](../docs_nexo/SDD_SKILLS.md). Estas fuentes comunes complementan la constitución y las specs, sin reemplazar contratos de API ni consumo móvil.

Las fases fueron refinadas con dependencias, datos, criterios específicos y tareas de preparación/comprobación. Siguen en Borrador documental: decisiones, contratos formales y revisión humana pendientes. No se instaló código, SDK, skills, infraestructura ni pipeline. Los documentos de requerimientos_nexolocal son referencias históricas; las fuentes adjuntas vigentes se consultan en docs_nexo.

## Aplicación local 0.3.0

Leer [mapa de estructura](docs/estructura-sdd.md) y [trazabilidad de la constitución](docs/trazabilidad-constitucion.md). Los requisitos tienen tareas y criterios vinculados por incremento. La revisión 0.3.0 corrige referencias a tareas antes ausentes; no cambia pendientes por resultados aprobados.

## Cobertura vigente 0.4.0

El desglose vigente contiene 25 specs en este contexto. Consultar [cobertura local](docs/cobertura-funcional.md) y [operaciones/funciones bilaterales](../docs_nexo/SDD_COBERTURA_FUNCIONAL.md). Cada EP propio y cada función/obligación de fuente tiene FR/tarea/AC, no solo mención en índice. Las asignaciones de fases de versiones anteriores quedan como historia; el inventario API y el índice actual son autoridad vigente.

## Herramientas IA del proyecto

Usamos Codex y Claude Code con una unica autoridad de reglas: AGENTS, constitucion, Memoria y spec objetivo. Ver [guia local de herramientas](docs/herramientas-ia.md). No hay configuracion de otra herramienta en este repositorio.
