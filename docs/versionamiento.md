# Matriz de versionamiento de la app

Requisito 11 del profesor: la matriz existe antes del desarrollo y se aplica en cada despliegue. El job **Versión · matriz y SemVer** del pipeline (`tools/ci/versionamiento.py`) falla si la versión de `pubspec.yaml` no aparece en esta tabla o si no coincide con la rama `release/x.y.z`.

## Reglas

| Parte | Formato | Cuándo cambia | Quién la pone |
|---|---|---|---|
| `MAYOR` | `X.0.0` | Cambia el contrato que la app consume y la versión anterior deja de funcionar con el backend | Equipo, en la rama release |
| `MENOR` | `0.Y.0` | Funcionalidad nueva (una o más specs) compatible con lo anterior | Equipo, al abrir `release/x.y.z` |
| `PARCHE` | `0.0.Z` | Solo correcciones en `release/*` o `hotfix/*` | Equipo |
| Build (`versionCode`) | `+N` | En cada AAB: `run_number` de GitHub + `BUILD_NUMBER_OFFSET` (100). Nunca se repite ni baja | Pipeline |
| Etiqueta | `vX.Y.Z` | Al fusionar `release/x.y.z` en `main` | Equipo |

- `pubspec.yaml` lleva `version: X.Y.Z+N`; la `N` local es solo de referencia, Play recibe la del pipeline.
- La app informa `APP_VERSION=X.Y.Z` al registrar el teléfono para push (`POST /v1/identity/devices`).
- Una versión ya subida a Play nunca se reutiliza: un rechazo o rollback publica un PARCHE nuevo.

## Matriz

| Versión | Build base | Rama | Specs incluidas | Backend que consume | Flutter / Dart | Pista Play | Estado |
|---|---|---|---|---|---|---|---|
| 0.1.0 | 100 | release/0.1.0 | 004, 017 (identidad y sesión) | `/v1/identity/*`, `/connect/token` | 3.29 / 3.7 | Ninguna | Histórica, sin publicar |
| 0.2.0 | 200 | release/0.2.0 | 026–048 (pantallas, resiliencia, pruebas, CI/CD, Play) | `/v1/identity`, `/v1/discovery`, `/v1/engagement`, `/v1/screens` | 3.29 / 3.7 | Ninguna | Histórica, sin publicar |
| 0.3.0 | 300 | release/0.3.0 | 049–052 (IA generativa y ML, push, SQLite y sincronización, privacidad y producción) | Lo anterior + `/v1/assist/draft`, `/v1/identity/devices` | 3.29 / 3.7 | Interna → producción | Preparada; pendiente de primera ejecución del pipeline |

Al publicar, actualizar la columna Estado con la fecha y el enlace a la ejecución de GitHub Actions; no marcar como publicada sin esa evidencia.

## Compatibilidad con el backend

| App | Contrato mínimo del backend | Si falta el endpoint |
|---|---|---|
| 0.3.0 | Identidad (login, refresh, logout) en producción | El resto de grupos usa datos de ejemplo con aviso visible (spec 045); el asistente de IA informa que no está disponible y la persona escribe a mano (spec 049) |
