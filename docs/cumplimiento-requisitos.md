# Cumplimiento de requisitos del profesor — parte móvil

Fuente: «Requerimientos para el desarrollo del proyecto Móvil v2» (septiembre–diciembre 2026, evaluación el 2 de diciembre de 2026). Esta tabla dice qué cubre este repositorio y con qué evidencia. **Preparado** significa que el código, las pruebas y el pipeline existen; **verificado** solo cuando GitHub Actions o un teléfono real lo ejecutó y quedó registrado en Memoria.

| # | Requisito | Dónde | Estado |
|---|---|---|---|
| 1 | Descargar la app desde Google Play | [048](../specs/048-publicacion-play-store/spec.md), [Play Store](play-store.md) | Preparado. Falta la primera subida manual en Play Console |
| 2 | Evaluación por prompts del proyecto | SDD completo (specs 001–052), [AGENTS](../AGENTS.md) | Preparado |
| 4 | App a la imagen de la maqueta, sin quitar funciones | Specs 026–044 | Preparado |
| 5 | SDD y DevSecOps | [Constitución](../constitution.md), specs, [pipeline](pipeline.md) | Preparado |
| 6 | Desarrollo con agentes de IA | [herramientas IA](herramientas-ia.md) | Preparado |
| 7 | Pruebas unitarias, de seguridad e integración | `test/unit`, `test/integration`, `test/security` ([046](../specs/046-pruebas-tres-capas-seguridad/spec.md)) | Preparado, sin ejecutar |
| 8 | CI/CD | `app-ci.yml` (54 jobs), Terraform `infra/github` ([047](../specs/047-ci-cd-github-terraform/spec.md)) | Preparado, sin ejecutar |
| 9 | Caché en el frontend | Caché SQLite por cuenta, ETag, catálogo 1 h ([051](../specs/051-cache-sqlite-sincronizacion/spec.md)) | Preparado |
| 10 | Logout en el móvil | `POST /v1/identity/logout`, baja de push y borrado local (041, 050, 051) | Preparado |
| 11 | Matriz de versionamiento aplicada en cada despliegue | [versionamiento](versionamiento.md) + job «Versión · matriz y SemVer» | Preparado |
| 12 | MCP | Uso del equipo, fuera de la app | No aplica al código |
| 16 | Despliegue desde GitHub a Google Play | Jobs AAB → Play interna/producción | Preparado |
| 16 | Moderar texto e imágenes antes de guardar | Backend (Content Safety); la app muestra `content.inappropriate` y `upload.rejected_by_moderation` ([052](../specs/052-privacidad-landing-produccion/spec.md)) | App preparada; depende del backend |
| 16 | Notificaciones push de los procesos principales | Firebase + `/v1/identity/devices` ([050](../specs/050-notificaciones-push/spec.md)) | Preparado. Falta proyecto de Firebase y el envío del backend |
| 16 | Aviso de privacidad vinculado a la landing | `LANDING_URL` + `/privacidad`, `/terminos` ([052](../specs/052-privacidad-landing-produccion/spec.md)) | Preparado. Falta publicar las páginas en la landing |
| 16 | Eliminar cuenta | `POST /v1/identity/me/deletion` + página `/eliminar-cuenta` | Preparado |
| 16 | Permisos del móvil | `tools/android/preparar_android.py` + revisión en CI | Preparado. Falta correrlo sobre la carpeta `android/` |
| 16 | Sesión siempre viva salvo logout | Token de renovación en almacenamiento seguro (004) | Preparado |
| 16 | SQLite y sincronización al volver la conexión | Caché y cola por cuenta ([051](../specs/051-cache-sqlite-sincronizacion/spec.md)) | Preparado |
| 16 | Al menos una función de ML y una de IA generativa | ML Kit en el teléfono (categoría por foto) y `POST /v1/assist/draft` ([049](../specs/049-ia-generativa-y-ml/spec.md)) | App preparada. El borrador generativo depende de que el backend publique EP-082 |
| 18 | Una sola cuenta de GitHub | Danix1219/NexoLocalApp | Cumplido |

Requisitos de nube, base de datos NoSQL, backend con dos instancias, Redis, CDN, observabilidad, SSL del backend y landing (3, 13, 14, 15 y 17) pertenecen a los repositorios del backend y de la landing; esta app solo los consume.

## Lo que falta para verificar

1. Correr `tools/android/preparar_android.py`, `flutter pub get`, `dart format lib test` y `flutter test`; hacer commit de `pubspec.lock` y `android/`.
2. `terraform apply` en `infra/github` con `landing_url` y los secretos (firma, `GOOGLE_SERVICES_JSON`, cuenta de servicio de Play).
3. Primer push a `develop` para obtener el grafo en verde; registrar el enlace en Memoria.
4. Primera subida manual a Play Console; después `release/0.3.0` sube sola a pruebas internas.
5. Backend: publicar `/v1/assist/draft` y `/v1/identity/devices`, y enviar push con el mismo proyecto de Firebase.
