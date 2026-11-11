# Memoria — App_NexoLocal

## Fase documental — adaptación al profesor (2026-11-02)
Estado: estructura y borradores documentales creados; sin implementación, compilación, suites de pruebas, CI o despliegue. El lint documental se registra por separado después de ejecutarlo.
Decisiones: adoptar el formato de WebSDD: specs/NNN-slug/spec.md → plan.md → tasks.md → checklist.md. Mantener requisitos Nexo, Flutter/microservicios/NoSQL y fuente única de contratos. Revisores por asignar.
Deuda: formalizar contratos del primer incremento, ratificar stack/costo/proveedores y convertir planes en rutas exactas cuando se creen proyectos. Ningún [x] o firma importado del profesor.
A evitar: confundir formato docente con obligación de SQL Server/Razor; llamar Borrador con evidencia a una fase sin pruebas de producto; volver a generar sdd/specs antiguo como si fuera el flujo activo.

## Verificación documental de la adaptación (2026-11-02)
Estado: `powershell -NoProfile -File scripts/check_sdd.ps1` devolvió exit 0 y SDD-OK: 15 specs; siete secciones, aprobación/control de cambios, tareas FR/NFR y enlaces relativos. No se ejecutaron Flutter analyze/test ni Android.
Decisiones: conservar `tasks.md`, `checklist.md`, constitución raíz y `specs/templates/`; adaptar roles/pantallas de WebSDD a Flutter sin Razor. Plantilla PR documental preparada, sin instalar herramientas.
Deuda: código móvil, permisos reales, tests, integración y firmas permanecen pendientes.
A evitar: copiar resultados del login Razor como si validaran sesión y privacidad del cliente Flutter.

## Reorganización de ubicación (2026-11-02)
Estado: traslado solicitado a `C:/Users/kevin/Downloads/App_NexoLocal`, fuera de requerimientos_nexolocal. Enlaces recalculados; validación posterior al traslado pendiente.
Decisiones: conservar ambos contextos como carpetas hermanas. Documentación funcional e histórica permanece en requerimientos_nexolocal.
Deuda: esto no crea repositorios Git ni implementación.
A evitar: ejecutar generadores antiguos que vuelvan a crear los proyectos dentro de la carpeta de requisitos.

## Redefinición SDD y coordinación API–app (2026-11-02)
Estado: documentación 0.2.0 refinada con fuentes de docs_nexo; planes, tareas, criterios y checklists por fase. Sin implementación ni aceptación de producto; validación final se registra por separado.
Decisiones: Codex y Claude Code sustituyen OpenCode como herramientas elegidas; entradas AGENTS/CLAUDE y traspaso secuencial. Autoridad de contratos API, consumo móvil; conservar las dos secuencias del profesor. Acuerdos comunes y cobertura en docs_nexo.
Deuda: ratificar decisiones D01–D08 pertinentes, asignar revisores humanos, formalizar contratos de la primera historia y concretar archivos/comandos de producto cuando se encargue. Skills investigadas y recomendadas, no instaladas.
A evitar: repetir responsabilidades del servidor como implementación Flutter, dar por Ready una fase por lint, afirmar costo cero/proveedores/SDK aprobados o marcar tareas sin evidencia real.

## Validación final de redefinición (2026-11-02)
Estado: validador local scripts/check_sdd.ps1 ejecutado con exit 0: 16 specs API y 15 móviles. Revisión adicional: 89 Markdown API, 80 app y 5 acuerdos comunes, sin fallos de enlaces/IDs/versiones; 101 EP coinciden entre inventario, Markdown fuente y fichas del XLSX de 116 hojas. Informe común: ../docs_nexo/SDD_VALIDACION.md.
Decisiones: registrar PASS solo documental. La revisión adicional fue una comprobación de sesión, no un script nuevo de producto. Las fuentes originales de docs_nexo se conservaron.
Deuda: revisión humana, decisiones D01–D08 pertinentes, contrato formal y pruebas de producto sin ejecutar. El resultado no concede Ready ni aceptación.
A evitar: presentar igualdad de IDs como compatibilidad completa de payloads o usar validación documental como prueba de APIs, Flutter, Android o nube.

## Aplicación constitucional e integridad estructural 0.3.0 (2026-11-02)
Estado: especificaciones, planes, tareas y checklists conciliados con constitución y mapas locales. Se detectó que T-006/T-007 estaban citadas pero ausentes; se corrigió y se añadieron tareas verificables, tabla FR/NFR→T→AC y AC-100 específico por propietario. Sin código de aplicación ni pruebas de producto.
Decisiones: API conserva 16 specs y concentra transversales en sus propietarios; app tiene 16 specs, incluida 016-sincronizacion-local para offline/cola/migraciones/conflictos/cambio de cuenta ya exigidos en fuente. Entrega móvil depende de esta aceptación. Codex/Claude secuenciales; no skills ni agentes instalados.
Deuda: D01–D08 pertinentes, responsable/revisor humano, contratos formales y rutas/comandos reales siguen pendientes antes de Ready/ejecución. Validación docente no cubre integridad semántica completa.
A evitar: citar tareas inexistentes, confundir cobertura de diseño con prueba ejecutada, duplicar autoridad de contratos o cargar funciones del servidor a Flutter. Informe vigente: ../docs_nexo/SDD_CIERRE_ESTRUCTURA.md; informe 0.2.0 conserva corrección explícita.

Comprobación adicional de sesión: 16 specs API con 172 tareas/140 requisitos/80 AC y 16 móviles con 174 tareas/142 requisitos/84 AC; cero fallos de enlaces, IDs citados, cobertura y ciclos locales en revisión API/copia móvil. No se añadió código de validador. Ejecución final del lint móvil y aplicación de copia se registra al aplicarla.

Validacion local tras aplicar 0.3.0: scripts/check_sdd.ps1, exit 0. SDD-OK: 16 specs; estructura/trazabilidad/enlaces documentales. Sin validacion de producto. Solo documental; sin pruebas de producto.

## Cobertura funcional y endpoints 0.4.0 (2026-11-02)
Estado: desglose documentado de 26 specs API y 25 móviles. Cada una de las 101 operaciones tiene FR/tarea/AC en spec primaria API; 92 tienen historia de consumo móvil y 9 exclusión directa interna/admin/infra. M01–M27, 13 componentes backend, W01, los 19 puntos académicos, seis tareas previas y H01–H12 tienen tarea/criterio propios por superficie pertinente. No producto implementado.
Decisiones: conservar IDs/métodos/rutas/propietarios y reasignar solo spec primaria para separar recuperación, catálogo, guardados/métricas, experiencias, interesados, notificaciones, datos/recuperación, expediente/landing, administración y consentimiento. Fases origen integran subcapacidades, sin volver a construir sus EP. No nuevo microservicio, endpoint ni pantalla inferida.
Deuda: esquemas exactos/compatibilidad/tipos, decisiones D01–D08, datos/cuentas/proveedores y revisión humana siguen pendientes antes de Ready/aceptación; opcionales/complementos se ratifican y no se presentan como obligaciones aprobadas.
A evitar: contar specs como prueba de cobertura semántica, equiparar documento a implementación, invocar internas/admin desde Flutter o duplicar casos de uso de spec primaria. Mapa vigente: ../docs_nexo/SDD_COBERTURA_FUNCIONAL.md; las asignaciones 0.3 son históricas.

Prevalidación adicional API/copia móvil: cero fallos de enlaces, referencias/duplicados, tareas, cobertura FR/NFR/AC y ciclos locales. Asignación única contrastada para 101 EP, 92 consumos y fuentes funcionales/académicas; 101 métodos/rutas coinciden con fuente 1.2.0. Aplicación y lint final se registran por separado.

Validacion local final 0.4.0: scripts/check_sdd.ps1, exit 0. SDD-OK: 25 specs; estructura/trazabilidad/enlaces documentales. Sin validacion de producto. Solo documental, sin producto ejecutado.

## Preparación de repositorios y CI documental (2026-11-02)
Estado: destinos públicos NexoLocalApi/NexoLocalApp verificados vacíos. CI documental preparado y probado desde copias aisladas: 26 specs API y 25 app, lint/IDs/cobertura PASS. Contextos externos congelados y hasheados evitan depender del disco local o acceso privado a otro repo. No build/test de producto ni CD.
Decisiones: raíces iniciales API_NexoLocal y App_NexoLocal con SDD y futuro código; plantilla .NET separada no se mueve. Workflow SDD / docs con acción oficial fijada a SHA, contents:read, sin credenciales de despliegue; bloquea manifiesto de producto hasta añadir CI real. Dependabot solo para Actions; ruleset de PR/revisión/check listo para aplicar tras primera ejecución remota.
Deuda: revisión humana adicional, Ready/contratos de identidad, stack/SDK, raíz de implementación final y nube/Play; publicación y ejecución remota se informan por separado, no inferidas por validar local.
A evitar: aprobar producto con lint, almacenar credenciales, añadir CD ficticio o describir snapshots documentales como HEAD vivo de la contraparte.

## Estado de configuracion de repositorios (2026-11-02)
Estado: Git local main/origin preparado, sin commit/push. Actions remoto configurado y verificado: SHA obligatorio, acciones oficiales seleccionadas, token de lectura y sin aprobacion automatica de PR; squash merge y borrado de rama tras merge. CI documental probado en copias aisladas (26 API/25 app), mas prueba negativa que rechaza manifiesto de producto sin CI real.
Decisiones: publicar solo tras autorizacion explicita del payload publico revisable. Revision automatica rechazo exponer SDD/Memoria/instrucciones/referencias sin esa autorizacion; no se sorteo el rechazo. Inventario: docs_nexo/PUBLICACION_INICIAL_REVISABLE.md.
Deuda: autorizacion publica, primer CI remoto y ruleset, persona revisora distinta del autor, Ready/contratos/stack de identidad y nube/Play para CD. CI documental no equivale a DevSecOps ni CD completos.
A evitar: anunciar push, pipeline remoto o rama protegida sin evidencia; enviar credenciales o confundir configuracion preparada con producto desarrollado.
## Autorizacion de publicacion y trabajo individual (2026-11-02)
Estado: el usuario autorizo explicitamente publicar el contenido revisable completo en ambos repositorios publicos con la identidad Git configurada. Se levanta el pendiente de autorizacion registrado anteriormente; commit/push y CI se verifican despues.
Decisiones: Danix1219 sera el unico responsable por ahora. Exigir PR y CI, con cero aprobaciones obligatorias para permitir trabajo individual sin fingir revision independiente; sin bypass de checks.
Deuda: incorporar revisor independiente y aumentar aprobaciones a uno cuando exista; contratos/Ready/stack y CD siguen pendientes.
A evitar: interpretar la autorizacion de publicacion como aceptacion funcional o revision independiente.

## Publicacion y CI remoto verificados (2026-11-02)
Estado: contenido autorizado publicado en https://github.com/Danix1219/NexoLocalApp; primer workflow SDD documentation y job SDD / docs concluyeron success: https://github.com/Danix1219/NexoLocalApp/actions/runs/41548583415. Upstream local/remoto 0/0 verificado despues del push inicial.
Decisiones: proteger main con PR, conversaciones resueltas y SDD / docs emitido por GitHub Actions (integration_id 15368), rama actualizada y sin force-push/borrado; cero aprobaciones por trabajo individual. La activacion se ejecuta tras verificar CI del commit que registra esta evidencia; resultado administrativo final en docs_nexo/INICIO_DESARROLLO_Y_REPOS.md.
Deuda: no existe revision independiente; Ready, contratos formales/stack y CI/CD de producto pendientes. No se han ejecutado builds, pruebas funcionales ni despliegues.
A evitar: confundir CI documental exitoso con aceptacion funcional, seguridad completa o CD.

## Flujo de equipo acordado (2026-11-02)
Estado: el usuario aclara que incorporara equipo y acuerda feature/*→develop→release/*→main. develop creada desde main; configuracion se entrega por PR, no push directo a ramas compartidas. Resultado final de PR/CI/rulesets se registra en docs_nexo/FLUJO_GIT_EQUIPO.md.
Decisiones: main principal; ramas por tarea/spec, candidato por entrega, estabilizacion fix→release y reintegracion main/release→develop. Checks SDD / docs y Git / flow, PR y conversaciones resueltas; merge commit en promociones, sin force-push/bypass. Dependabot a develop; borrado automatico deshabilitado para no perder ramas antes de reintegrar.
Deuda: solo Danix1219 figura hoy como colaborador; al aceptar el primer revisor Write, subir aprobaciones de 0 a 1 en los tres rulesets de ambos repositorios antes del trabajo de equipo. CD/CI de producto y Ready permanecen pendientes.
A evitar: PR feature/develop directo a main, funcionalidades nuevas en release, olvidar reintegracion, borrar develop o presentar la fase transitoria como revision independiente. El acuerdo anterior de trabajo individual queda sustituido por este flujo de equipo.

## Preparacion Jira/Confluence (2026-11-02)
Estado: plantillas PR, convencion tipo/CLAVE-JIRA-descripcion, validador de metadatos y pruebas preparados en ambos repositorios en rama temporal local. Datos Jira/Confluence reales solicitados y aun pendientes; sin publicar ni activar reglas remotas nuevas. Resultado de validacion local se registra en docs_nexo/TRAZABILIDAD_JIRA_CONFLUENCE.md.
Decisiones: enlace Jira y pagina Confluence obligatorios tambien para bots/promociones/reintegraciones; titulo, clave principal y rama de trabajo coinciden. Workflow usa codigo de main de confianza y no consulta servicios ni ejecuta codigo del PR. No instalar ni afirmar integracion Jira automatica.
Deuda: clave/proyecto Jira, bases HTTPS, tarea/pagina reales para este cambio; renombrar rama temporal con tarea real, publicar por flujo aprobado, verificar check real y anadirlo a los seis rulesets. CI documental y aceptacion de producto siguen siendo distintos.
A evitar: enlazar portadas como documentacion, aceptar enlaces solo ocultos/comentarios, inventar tickets o publicar/activar un gate sin configuracion real.

## Limpieza de herramientas IA (2026-11-03)
Estado: retirada .opencode de la app por encargo explicito; referencias activas README/AGENTS/CLAUDE/mapa/constitucion/spec 001 alineadas con Codex y Claude Code. Guia docs/herramientas-ia.md.
Decisiones: AGENTS es entrada/procedimiento comun; CLAUDE remite a esa autoridad. Conservar flujo Flutter, autoridad de contratos API y ejecucion secuencial; sin perfiles ajenos ni configuraciones ficticias. Inventarios historicos y snapshots mantienen su revision.
Deuda: verificar carga efectiva y skills al utilizarlos; Jira/Confluence y publicacion siguen pospuestos.
A evitar: reglas divergentes, atribuir instalaciones o agentes a un README, copiar estructura .NET al movil o reescribir evidencia historica.

Verificacion: scripts/check_sdd.ps1 exit 0, SDD-OK 25 specs; git diff --check correcto y carpeta retirada. Solo cambios locales, sin publicacion ni codigo Flutter.

## Preparación de publicación autorizada (2026-11-03)
Estado: el usuario encarga subir todos los cambios a sus repositorios; el móvil conserva solo cambios documentales/gobierno/IA, sin producto Flutter. Se prepara rama provisional chore/publicacion-alineacion-app; no se publica directamente en ramas compartidas ni se fusiona PR sin Jira/Confluence reales.
Decisiones: conservar actualización de checkout ya fusionada en origin/develop. CI documental se ejecutará también en ramas de trabajo; guard de manifiesto Flutter permanece, sin CI de producto ficticio. Referencias compartidas se actualizan como snapshot revisable con hashes; no trasladar solución .NET al móvil.
Deuda: confirmar push y CI remoto después de publicar; Jira/Confluence, revisión humana y Ready siguen pendientes. El cambio autoriza publicación en rama, no inventar tickets ni activar reglas remotas nuevas.
A evitar: subir secretos/cachés, mezclar repositorios, declarar aceptación funcional por publicar documentación o sobrescribir el avance remoto del equipo.

Publicación verificada (2026-11-03): rama chore/publicacion-alineacion-app enviada a https://github.com/Danix1219/NexoLocalApp; primer HEAD publicado 7830d89. Push exitoso, upstream configurado, árbol limpio y divergencia 0/0 comprobados. Se preserva origin/develop mediante merge sin conflictos. GitHub inició CI: https://github.com/Danix1219/NexoLocalApp/actions/runs/41691271267; en curso al registrar esta evidencia, sin afirmar aprobación anticipada. No PR/merge a ramas compartidas por falta de metadatos Jira/Confluence reales.

## Implementación app, pruebas en tres capas y CI/CD (2026-11-08)
Estado: app Flutter en `src/mobile/nexo_app` (v0.2.0+200) con pantallas de las specs 026–044 y consumo del backend por grupos con datos de ejemplo cuando un endpoint no responde (045). Pruebas reorganizadas en `test/unit` (11), `test/integration` (10) y `test/security` (6). Pipeline `app-ci.yml` de 42 jobs generado, Terraform `infra/github` (rulesets, entornos `firma`/`staging`/`production`, variables) y publicación a Play interna/producción preparados (046–048). `flutter analyze` local sin errores reportado por el usuario sobre la versión previa a esta entrega.
Decisiones: un job por archivo de prueba para ver en el grafo exactamente cuál falla; checks requeridos generados desde la misma lista que los jobs; simulación de contraparte solo en depuración o `API_MODE=fake` (excepción §11); PUT de imágenes firmadas sin Bearer; enlaces profundos solo con esquema propio y secciones conocidas.
Deuda: las pruebas, el pipeline y `terraform validate` NO se han ejecutado todavía (sin SDK Flutter ni Terraform en el entorno donde se generaron); falta `pubspec.lock` versionado, firma en `build.gradle.kts`, `allowBackup=false` en el manifiesto, primera carga manual en Play Console, secretos reales y `terraform apply`. SQLite por usuario (016) y push (022) siguen sin implementar. Specs 026–048 permanecen en Borrador documental.
A evitar: declarar verde un job que no corrió, editar `app-ci.yml` a mano, publicar a producción sin revisor del entorno, usar datos de ejemplo como evidencia de integración o subir keystore/tfstate.

## Requisitos de producción del profesor (2026-11-08, app 0.3.0)
Estado: revisado el documento «Requerimientos Móvil v2». Se agregaron ML en el teléfono (ML Kit, categoría por foto) e IA generativa (`POST /v1/assist/draft`), push con Firebase (`/v1/identity/devices`), caché SQLite por cuenta con ETag y cola de publicar solicitud sin señal, enlaces al aviso de privacidad/términos/baja en la landing, mensajes de moderación, script de Android y matriz de versionamiento con job propio. Specs 049–052; pipeline regenerado a 54 jobs (53 checks requeridos). Grafo en `docs/pipeline.md` y `docs/img/pipeline-grafo.png`.
Decisiones: base URL de producción HTTPS por omisión; el AAB falla sin Firebase, sin `LANDING_URL` HTTPS o con versión fuera de la matriz; asistente y registro de push no activan el aviso de datos de ejemplo; en release la maqueta no inventa borradores de IA.
Deuda: NADA de esto se ha compilado ni probado todavía (sin SDK Flutter ni red en el entorno donde se generó); las versiones de los paquetes nuevos se confirman con `flutter pub get`. Faltan: proyecto Firebase y su secreto, páginas legales de la landing, EP-082 y devices en el backend, evaluación del modelo de ML con datos propios (013) y la primera subida a Play.
A evitar: presentar plantillas de la maqueta como IA, subir `google-services.json`, publicar a producción sin aviso de privacidad o declarar verificado lo que solo está preparado.


### 2026-11-09 — Integración Identity/Cuenta

GET /me plano, correo verificado, celular declarado sin SMS, cambio de modo con refresh OAuth y recuperación de baja mediante recovery_only. Cuenta fuera de caché y sin fallback automático de identidad/operaciones destructivas. Tres archivos de pruebas actuales ampliados: 215 casos aprobados con cobertura en copia de validación. Sin teléfono Android conectado; SMTP/Atlas/Firebase reales no validados. Ver docs/integracion-identity-cuenta.md.

Verificación posterior: APK debug compilado, instalado en Android conectado conservando datos y abierto con Status: ok. Proceso activo y sin errores AndroidRuntime/Flutter en la comprobación de arranque. El recorrido con Gmail/Atlas/Firebase reales permanece sin validar.


### 2026-11-09 — Ubicacion real y Mi perfil

Registro: mapa/GPS con consentimiento, seleccion obligatoria y envio del punto/radio elegidos. Tras el alta se guarda en Discovery. Cuenta: PUT real, sin fallback de guardado simulado; seleccion local segura aislada por accountId. GPS sin permiso o apagado permite mover el mapa. No hay geocodificacion de colonias: mostrar coordenadas aproximadas, nunca nombres de zonas ficticios.

Mi perfil se abre desde la tarjeta propia con portada visual, foto disponible, nombre, correo verificado y accion separada de editar. Actividad sin implementar aparece proximamente. Fotos se anuncian proximamente por confirmacion del usuario: Blob Storage y moderacion no configurados; no se crearon recursos cloud.

Las rutas inexistentes (404/405/501 sin codigo Nexo) muestran Proximamente sin boton Reintentar. Errores de autenticacion, red y negocio mantienen su tratamiento. Pruebas ampliadas en archivos existentes de integracion/seguridad; no se agregan jobs ni se aplica Terraform.

Verificacion del incremento: 217 pruebas Flutter aprobadas con cobertura; 97 pruebas backend aprobadas. APK debug con API local compilado, instalado conservando datos y abierto en Android (Status: ok). Endpoint PUT de ubicacion disponible en 5188; peticion anonima devuelve 401. GPS sobre hardware y recorrido de alta/cambio con usuario real quedan para comprobacion interactiva del usuario. Etiquetas de ubicacion muestran coordenadas aproximadas: geocodificacion de colonias pendiente. No se configuro ni simulo Blob/moderacion.


### 2026-11-09 — Recorridos de maqueta y paridad visual (053)

Estado: recorridos de ambos roles examinados en Chrome; navegación compartida, Mi perfil visual, fuentes locales con licencia, entradas/pulsaciones/pestañas/chat y movimiento reducido aplicados en Flutter. Correo verificado conserva la decisión real de producto y no se confunde con celular declarado.

Verificación: 225 pruebas Flutter aprobadas con cobertura; analyze sin errores ni warnings, con 13 infos. Pipeline regenerado a 54 checks requeridos al añadir archivo de widgets; sin Terraform apply. Detalle y límites en docs/paridad-visual-maqueta.md.

Deuda: aceptación visual humana, todas las combinaciones de estados/tamaños, selector de ubicación como hoja y geocodificación. Fotos siguen Próximamente sin Blob/moderación. A evitar: copiar datos demo, declarar paridad total por pasar pruebas o presentar recorrido de Chrome como validación real de Atlas/Gmail en Android.

APK visual debug compilado con API local. Instalación actual pendiente: adb devices sin teléfono conectado; no confundir con la instalación previa del incremento de ubicación. Workflows: WORKFLOWS-OK. SDD conserva enlaces históricos rotos; ejecución local se registra separada de casillas documentales y aceptación humana.


### 2026-11-09 — Integración de perfiles backend en Flutter (054)

Estado: alta/propio/público/edición/comparación conectados al contrato de grupo 03. Se corrigen bio en services, slugs de especialidades, tipo persona/negocio, importes con centavos, condiciones y punto privado propio. Alta conserva llave y no repite creación si solo falla el cambio de modo.

Decisiones: perfil sin fallback automático ni caché privada; solo fake explícito. Fotos/portada próximas por falta de infraestructura. Catálogo inicial mapeado localmente, pendiente bloque 04 autoritativo. No se modifica backend ni .env.

Deuda: recorrido con cuenta real en Android, moderación cloud y catálogo/búsqueda/trabajos/opiniones pendientes. Evidencia de suites y APK se registra al cierre en docs/integracion-perfiles.md; un doble Dio no acredita Atlas/Gmail ni aprobación humana.

Cierre de 054: 237 pruebas aprobadas con cobertura (12 nuevas); analizador sin errores ni warnings, 13 infos pendientes. WORKFLOWS-OK y diff --check aprobados. SDD mantiene enlaces históricos rotos; la spec 054 no añade fallos propios. APK live compilado, instalado -r y abierto en Android (Status ok); reverse USB 5188. API actual ejecutándose en 5188 con health/ready 200 y cinco rutas de perfiles en OpenAPI. No se recorrió alta real ni se acreditó moderación cloud. No se publicaron cambios.


### 2026-11-09 — Corrección visual por pantalla y menú duplicado (055)

Estado: /my-profile en navegador raíz y hojas raíz eliminan barra duplicada. Se corrigen fuentes Nunito (peso variable inicial 200) con caras 400–800 explícitas, portada/avatar, títulos/pestañas, cabeceras fijas, listado Buscar, feed ancho completo con fotos cuadradas/contacto verde, tarjetas Solicitudes/Interesados y ubicación como hoja. Matriz de pantallas y límites en docs/revision-visual-pantallas.md.

Evidencia: 242 pruebas completas aprobadas con cobertura, 14 regresiones visuales finales; analyze cero errores/warnings y 13 infos previos. APK live compilado e instalado -r conservando datos, reverse5188 y API ready200. Arranque inicial timeout, posterior Status ok y UI renderizada. Mi perfil abierto por el usuario: árbol físico con una sola instancia de cada destino; capturas observadas de Inicio/Cuenta/Buscar. Android bloquea inyección de toques USB; no se cambiaron permisos.

Deuda: aceptación visual humana exhaustiva, geocodificación/búsqueda de direcciones, Blob/moderación y endpoints pendientes. SDD mantiene enlaces históricos rotos, workflows OK y diff sin errores; sin commit/push/Terraform. A evitar: afirmar equivalencia píxel a píxel, presentar capturas de otra pestaña como Mi perfil o equiparar tests de widgets con cloud real.


### 2026-11-10 — Ubicación real y confirmación del registro (056)
Estado: geocodificación Photon mediante Discovery sin demo; selector compartido con búsqueda explícita, mapa/GPS/radio y atribución. Restore del servidor/caché segura por cuenta con protección contra respuestas obsoletas, sin asignar centro inicial. Alta muestra confirmación explícita incluso si falla login o ubicación; reintentar zona no repite creación. Buscar ajustado a fondo/controles de maqueta.
Verificación: 250 pruebas completas con cobertura, 19 widgets de diseño, y 55 finales de caché/seguridad; analyze sin errores/warnings y 13 infos previos. API real búsqueda/inversa Tula HTTP200; backend ready200. APK live compilado; instalación final registrada en docs/ubicacion-real-y-registro.md.
Deuda: GPS físico, alta nueva/entrega Gmail con usuario real, aceptación visual exhaustiva, proveedor geocoding con SLA para volumen y endpoints de búsqueda de prestadores. Fotos pendientes. Sin claves ni .env nuevos, commit/push o Terraform. Evitar guardar consultas privadas en SQLite o convertir fallos del proveedor en resultados ficticios.

### 2026-11-10 — Integración móvil hasta grupos 01–06 (057)
Estado: catálogo real categories, filtros/selección, búsqueda/sugerencias/mapa y solicitudes del mapa; trabajos publicar/listar/borrar/recomendar/retirar desde perfil, solicitudes publicar/mine/opportunities/close en pantallas existentes. Cursores completos sin truncar primera página. Reintento de trabajo estable por payload; cierre pickedProviderId solo solvedHere. Fotos sin infraestructura Próximamente; omitir imágenes demo. Sin fallback automático en grupos publicados; resumen degradado conserva desconocido. Consultas/estados privados sin caché obsoleta ni coordenadas/consultas en logs.
Verificación: 260 pruebas con cobertura, 10 nuevas en archivos de las tres capas existentes; sin nuevos jobs ni Terraform. Workflows OK, diff-check 0. SDD conserva deuda histórica externa; spec057 enlaza autoridad backend real. Detalle y resultado APK en docs/integracion-backend-01-06.md. No es validación de Atlas/Content Safety/recorrido físico completo ni firma humana.
Deuda: feed, interés y otros grupos pendientes no se inventan; publicación requiere Content Safety y conectividad Mongo reales. Backend anterior ready503 por Mongo no disponible; no cambiar secreto/conexión para fingir salud. Sin commit/push, backend modificado ni despliegue.

Cierre operativo 057: APK debug live compilado para http://127.0.0.1:5188, adb install -r Success conservando datos, reverse5188 y arranque Status ok. Proceso Android activo y sin AndroidRuntime:E/flutter:E en smoke. API health/ready200 verificado actualmente, sustituye limitación histórica ready503 sin cambiar conexiones. No se recorrió publicación real ni se creó contenido de prueba en la cuenta del usuario. Analizador 0 errores/warnings y 12 infos; Flutter reporta salida no cero por diagnósticos, no afirmar análisis sin observaciones. Check SDD conserva deuda histórica, sin errores propios de 057.


### 2026-11-10 ? Fotos reales conectadas
Estado: avatar, portada personal/profesional y fotos en solicitudes/trabajos usan Azure a trav?s de API. Polling hasta approved; ninguna imagen processing se vincula. Preserva borrador y foto anterior al fallar. El PUTBlob va sin Bearer y sus SAS no aparecen en logs. 267pruebas aprobadas con cobertura, analyze0errores/0warnings y13infos existentes; APK debug live instalado -r y app abierta sin borrar datos.
Decisiones: API posee contratos de medios; Flutter no lleva claves ni accede a DB. MyProfile consume GET/PUT me/cover; PATCHidentity y perfil profesional existentes reciben uploadId aprobado. Solo fake expl?cito simula medios; grupo real sin fallbackdemo.
Deuda: recorrido f?sico de galer?a/c?mara y todas las pantallas por usuario. Cloud validado por backend con imagen sint?tica aislada y limpieza; no se probaron fotos privadas del usuario. Sin CDN/chat privado. APIlocal5188 con adb reverse; para despliegue fijar PublicBaseUrlHTTPS del backend. Revisi?n humana pendiente.
A evitar: confundir dobles HTTP con Azure o instalaci?n con publicaci?n remota. No secretos, commits/push ni nuevos archivos de test/jobs/Terraform.


### 2026-11-10 ? Lectura de publicaciones y corrección de avatar
Estado: tarjetas de trabajos y solicitudes muestran tres líneas y Ver más/Ver menos si desborda; aprovechan descripción completa del backend. Los errores de formato y resolución de foto se muestran por separado del rechazo de moderación. APK debug/live actualizado, instalado sin borrar datos y abierto en teléfono.
Decisiones: el filtro de imágenes backend acepta nivel bajo y bloquea medio/alto, con política de texto independiente. No se asume cuál fue la clasificación de la foto real previa.
Verificación: Flutter269/269 con cobertura, analyze0errores/0advertencias y13infos anteriores; backend242/242, APIready200. check_sdd.ps1 móvil falla por incidencias históricas ajenas al incremento 057.
Deuda: el usuario debe repetir una carga con su foto para verificar la clasificación actual. Revisión humana pendiente. A evitar: afirmar prueba de esa foto o despliegue remoto por haber instalado el APK.

### 2026-11-10 — Fotos, zona y navegación 059
Estado: shimmer localizado durante subida/moderación de avatar y portada en perfiles personales y profesionales, incluido alta profesional; miniaturas para avatar, vista de autor de solicitud con datos públicos y retroceso de pestañas al Inicio. flutter test 275/275; APK debug live compilado. APK instalado en 2201116SG por ADB sin streaming, reverse 5188 activo y aplicación abierta; aceptación visual y prueba de fotos reales pendientes; flutter analyze sin errores ni advertencias, 19 avisos informativos.
