# AGENTS — App_NexoLocal

Rector: [constitution.md](constitution.md). Este archivo dice cómo trabajar; la constitución qué reglas respetar.

## 1. Forma de trabajo
Leer constitución, este archivo, Memoria y la spec objetivo. Seguir `specs/NNN-slug/spec.md → plan.md → tasks.md → checklist.md`. Fase actual (2026-11-08): implementación de la app en `src/mobile/nexo_app` con CI/CD preparado. Crear nube, cuentas o publicaciones solo con encargo explícito.

## 2. Memoria y cierre
Actualizar Memoria al cerrar fase: Estado/Decisiones/Deuda/A evitar. Conciliar spec/plan/tareas/checklist con archivos y resultados reales. No firmar sin revisor humano identificado.

## 3. Límites
No tocar API_SDD ni WebSDD. Sin secretos ni resultados inventados. Sin acceso directo desde Flutter a MongoDB/Neo4j. No copiar SQL/EF, TOTP, cookies Razor, una sola instancia, ni exclusión de Redis/CD como si fueran requisitos Nexo.

## 4. Verificación
Ejecutar `scripts/check_sdd.ps1` desde esta carpeta; su PASS solo acredita estructura. Comandos reales de la app (desde `src/mobile/nexo_app`): `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test test/unit`, `flutter test test/integration`, `flutter test test/security`, `flutter test --coverage`. No usar comandos del profesor contra carpetas inexistentes.

## 5. Contratos y docs vivos
API posee contratos y rutas; app registra consumo/pantallas y enlaza la autoridad. FR/NFR se identifican localmente por spec; toda tarea incluye referencia y criterio. No añadir operaciones inventadas para cada botón.

## 6. Seguridad y pruebas
Cubrir H01-H12 pertinentes, aislamiento, consentimiento, estados y reintentos. Distinguir dobles unitarios de integración real. La moderación o SMS simulados no aprueban aceptación productiva.

## 7. Roles con IA
Herramientas del equipo: Codex y Claude Code. Ver [procedimiento compartido](../docs_nexo/SDD_HERRAMIENTAS_IA.md) y [acuerdo de alineación](../docs_nexo/SDD_ALINEACION.md). Roles documentados no activan herramientas ni subagentes. Ejecutar secuencialmente salvo autorización explícita para delegar. Mínimo privilegio y revisión humana.

## 8. Fuentes y coordinación
Leer [fuentes y brechas](../docs_nexo/SDD_COBERTURA_Y_BRECHAS.md) y la spec de la contraparte cuando cambie una frontera. Conservar contratos en API y consumo/pantallas en app. Resolver decisiones bloqueantes antes de Ready. Consultar [skills recomendadas](../docs_nexo/SDD_SKILLS.md) sin instalarlas ni ampliar permisos automáticamente.

## 9. Integridad local de la estructura
Leer [estructura SDD](docs/estructura-sdd.md) y [trazabilidad constitucional](docs/trazabilidad-constitucion.md). Verificar que cada FR/NFR tenga tarea y cada AC comprobación, que todos los T-ID citados existan y que las dependencias locales no formen ciclos. El validador actual no garantiza esas propiedades por sí solo; registrar revisión adicional sin presentarla como prueba de producto.

## Flujo Git del equipo (acuerdo 2026-11-02)

Aplicar [flujo Git](docs/flujo-git.md): ramas por tarea desde develop, PR a develop, candidato release/* y PR de release a main; reintegrar main a develop. main permanece principal. CI y PR obligatorios; revision independiente exigible al incorporar revisor real. No declarar Ready o aceptacion por publicar o fusionar documentacion.

## Trazabilidad de cambios Jira/Confluence (2026-11-02)

Aplicar [convencion de cambios](docs/trazabilidad-jira-confluence.md): rama de trabajo con clave Jira y PR con titulo/clave coincidentes, enlace al ticket y enlace obligatorio a la pagina Confluence del cambio. API y app conservan su autoridad SDD; Confluence no reemplaza contratos versionados. No inventar tickets, enlaces ni firmas; activar el check requerido solo con configuracion real y ejecucion verificada.

## 10. Implementación y pipeline (2026-11-08)

- Cada pantalla o función tiene spec/plan/tasks/checklist (026–048). Cambiar comportamiento observable empieza por la spec.
- Pruebas en tres capas: `test/unit`, `test/integration`, `test/security`. Un archivo nuevo de prueba → ejecutar `python3 tools/ci/generar_pipeline.py` y commitear `app-ci.yml` y `infra/github/checks.auto.tfvars.json`; después `terraform apply` en `infra/github` para actualizar los checks requeridos.
- Nunca editar a mano `app-ci.yml`; editar el generador.
- Acciones de GitHub fijadas por SHA (`python3 tools/ci/revisar_workflows.py`).
- Endpoints que no existen todavía: no desactivar el modo `auto`; la spec 045 define cuándo se usan datos de ejemplo. No convertir errores de negocio en datos de ejemplo.
- Sin secretos en el repositorio: keystore, `key.properties`, JSON de Play y `terraform.tfstate` están ignorados y viven en GitHub/entorno local.
- Registrar en Memoria qué se ejecutó de verdad (comando y resultado o enlace a la ejecución); lo no ejecutado se declara como pendiente.

## 11. Producción 0.3.0 (2026-11-08)

- Specs 049–052 cubren IA/ML, push, caché SQLite y privacidad/versionamiento. Mapa de requisitos del profesor: [cumplimiento](docs/cumplimiento-requisitos.md).
- Antes de abrir `release/x.y.z`: subir `version:` en `pubspec.yaml` y agregar la fila en `docs/versionamiento.md`.
- Android: `python3 tools/android/preparar_android.py src/mobile/nexo_app` después de crear o cambiar `android/`.
- Nunca subir `google-services.json`, `key.properties`, `*.jks` ni `terraform.tfstate`.
