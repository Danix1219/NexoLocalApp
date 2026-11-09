# Runbook de entrega

El formato toma como referencia el release por slice del profesor. Desde 2026-11-08 la app tiene pipeline real preparado; los pasos siguientes describen cómo usarlo. Nada se considera publicado hasta que exista la ejecución en GitHub Actions y la versión en Play Console.

## Preparación única

1. Aplicar `infra/github` con Terraform (ver [README](../infra/github/README.md)): rulesets, entornos `firma`, `staging`, `production` y variables (incluida `LANDING_URL`).
1. Preparar Android: `python3 tools/android/preparar_android.py src/mobile/nexo_app` y commit de `android/`.
1. Firebase: secreto `GOOGLE_SERVICES_JSON` en el entorno `firma`.
2. Generar la keystore de subida fuera del repositorio y cargar los secretos del entorno `firma` (ver [Play Store](play-store.md)).
3. Crear la app en Play Console, aceptar firma de apps de Google Play y subir a mano el primer AAB a prueba interna.
4. Crear la cuenta de servicio con acceso a la app y guardar su JSON como secreto de `staging` y `production`.

## Por cada versión

1. Identificar specs incluidas, versión de `pubspec.yaml`, commit y ejecución de CI.
2. Subir `version:` en `pubspec.yaml`, agregar la fila en [versionamiento](versionamiento.md) y desde develop crear `release/x.y.z`; el pipeline ejecuta todas las pruebas, firma el AAB y lo sube a prueba interna (`PLAY_STATUS`, por omisión `draft`).
3. Verificar en un teléfono real el recorrido, permisos, aviso de datos de ejemplo y la URL del backend.
4. Solo correcciones en release/*; cada push vuelve a ejecutar todo.
5. PR de release a main; al fusionar, el job de producción espera la aprobación del revisor del entorno `production`.
6. Reintegrar main a develop.
7. Registrar en Memoria versión, enlaces a ejecuciones y resultado de la verificación manual.

## Rollback

En Play Console detener el lanzamiento o promover la versión anterior; corregir en `hotfix`/`release` y subir un build-number mayor (nunca reutilizar uno).

## Cierre global

El cierre de entrega requiere cada fase obligatoria aceptada y trazabilidad de API/app; S08/shortlist opcionales no bloquean si no se habilitan. El paquete académico incluye .rar sin secretos, guía reproducible, versiones/manifiesto y evidencia de instalación/evaluación.
