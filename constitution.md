# Constitución — App_NexoLocal

Versión: 0.3.0 documental. Estado: Borrador; pendiente de ratificación técnica. Fuente de verdad: `constitution.md`.

## 1. Propósito y alcance

App Flutter que consume las APIs de Nexo. Una spec describe un recorrido de pantalla→ViewModel→repositorio→API/SQLite; no acceso directo a bases del backend.

## 2. Principios

Fuentes vigentes: requisitos académicos, maqueta aprobada y hallazgos H01-H12. Seguridad, aislamiento por usuario, datos mínimos, fallos explícitos y evidencia verificable. Spec antes de cambio observable. Nunca inferir autorización de los alias Tú/me ni del modo de pantalla. No copiar los defectos de la maqueta como reglas permitidas.

## 3. Stack

Flutter confirmado por usuario. MVVM por funcionalidad, repositorios y adaptadores propuestos; Riverpod/go_router por ratificar y fijar versiones. Almacenamiento local SQLite separado por usuario y credenciales en almacenamiento seguro.

Fijar versiones exactas y evaluar dependencias al preparar la primera implementación; no hay paquetes instalados por estos documentos.

## 4. Arquitectura

Vista→ViewModel→caso de uso/repositorio→adaptador remoto/local. El servidor sigue autorizando y moderando. Estado de sesión y caché se purga por cuenta; el cliente no simula aceptación de contraparte.

## 5. Contratos y datos

Autoridad de inventario: `API_NexoLocal/docs/contracts/inventario.json`. OpenAPI/AsyncAPI/SDL formales pendientes por incremento. docs/endpoints indexa, no sustituye los esquemas. IDs y dinero/fechas según contratos de Nexo, sin copiar prefijos SQL ni PascalCase legacy. Regla de teléfono/domicilio por estado y consentimiento.

## 6. Configuración y seguridad

Sin secretos en archivos, errores o logs. Configuración por entorno. Redis no es historial durable ni una caché expulsable para revocación. Moderar antes de persistir contenido; rechazar por omisión cuando no se puede comprobar autorización. CORS/headers web se aplican a superficies HTTP pertinentes; no inventar antiforgery de Razor para Flutter.

## 7. Gobernanza SDD

Flujo `specs/NNN-slug/spec.md → plan.md → tasks.md → checklist.md`. Un cambio pequeño por revisión, tareas con FR/NFR y aceptación verificable. Docs vivos en docs/, especificaciones los enlazan. Rama de trabajo futura según id de spec. Un revisor humano real; no copiar firmas del profesor. Borrador documental → refinada → lista para desarrollar → implementada con evidencia → aprobada; Borrador con evidencia solo tras ejecutar producto y documentar resultados.

Cada FR/NFR debe aparecer en una tarea definida y cada AC tener comprobación asignada. No citar tareas ausentes ni mantener dependencias circulares. La cobertura de diseño queda en tabla por spec; plan y checklist deben usar los mismos IDs. Las capacidades transversales tienen dueño único y los recorridos enlazan su integración.

## 8. Gates de calidad

Hoy solo lint documental. Al implementar: restore Flutter→analyze→unit/widget→integration→security checks→critic→endpoints→sdd→coverage→delta advisory→SAST; definir herramientas y comandos reales en la fase de calidad. Cobertura 45% y delta 80% advisory se toman como base docente a ratificar; jamás sustituyen casos críticos de permisos. No crear CI ficticio ni indicadores verdes sin ejecución.

## 9. Entrega y operación

Nexo requiere CI/CD, nube, dos instancias HTTP, TLS, observabilidad, CDN y Play/landing, aunque los ejemplos pospongan hosting/CD y Redis. Costo cero se verifica con cuenta/región. Una publicación, pipeline o despliegue requiere el encargo correspondiente; esta entrega es documental.

## 10. Memoria

Memoria.md registra Estado, Decisiones con porqué, Deuda y A evitar por fase. Breve, sin datos sensibles. Una regla permanente se documenta en constitución/AGENTS. No confundir esta bitácora de proyecto con la memoria global del asistente.

## 11. Revisión y excepciones

Registrar diferencia con el profesor y razón de producto, manteniendo formato y secuencia. Ratificar stack/proveedores y responsable antes de Ready del primer incremento. Controles propuestos y escenarios de aceptación no son pruebas ejecutadas.

## 12. Herramientas y coordinación acordadas

El equipo utilizará Codex y Claude Code; OpenCode/WARP pertenece al ejemplo docente. AGENTS es el procedimiento común y CLAUDE es entrada de lectura, sin duplicar reglas. Ejecución secuencial y revisión humana; roles documentados no activan subagentes.

Aplicar el [acuerdo SDD](../docs_nexo/SDD_ALINEACION.md), [cobertura de requisitos](../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y [protocolo IA](../docs_nexo/SDD_HERRAMIENTAS_IA.md). La matriz de versiones precede al desarrollo; CI/CD y canal móvil se preparan desde primera vertical, mientras entrega cierra evidencia global. Mantener propuestas técnicas como tales hasta ratificar y resolver bloqueantes de la historia antes de Ready.

La spec 016-sincronizacion-local es autoridad de cola/migraciones/reconciliación; los recorridos conservan negocio y la API sus permisos. El cierre 014 incluye esta capacidad obligatoria; no habilita pedidos/contacto offline.

## Flujo Git del equipo (acuerdo 2026-11-02)

Aplicar [flujo Git](docs/flujo-git.md): ramas por tarea desde develop, PR a develop, candidato release/* y PR de release a main; reintegrar main a develop. main permanece principal. CI y PR obligatorios; revision independiente exigible al incorporar revisor real. No declarar Ready o aceptacion por publicar o fusionar documentacion.
