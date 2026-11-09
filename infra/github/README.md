# Infraestructura de GitHub con Terraform (spec 047/048)

Configura el repositorio de la app para que **nada llegue a `develop`, `release/*` o `main` sin pasar cada prueba**, y prepara los entornos para publicar en Play Store.

| Recurso | Qué hace |
|---|---|
| `github_repository_ruleset.flujo` (main, develop, release) | Sin borrar ni force-push; PR obligatorio con conversaciones resueltas y merge commit; **todos** los checks de `checks.auto.tfvars.json` en estricto (rama al día). |
| Entorno `firma` | Guarda la llave de subida de Android. Solo `main` y `release/*` pueden usarlo. |
| Entorno `staging` | Pista de pruebas internas de Play. Solo `release/*`. |
| Entorno `production` | Pista de producción. Solo `main` y con aprobación de `production_reviewers`. |
| Variables de Actions | `FLUTTER_VERSION`, `API_BASE_URL`, `API_MODE`, `PLAY_STATUS`, `MIN_COVERAGE`, `ANDROID_PACKAGE_NAME`. |
| Secretos (opcional) | Llave de firma y cuenta de servicio de Play, si `manage_secrets = true`. |

## Uso

```powershell
cd infra/github
# Token fino de GitHub con Administration, Environments, Secrets y Variables (lectura/escritura) del repo.
$env:GITHUB_TOKEN = "<token>"
copy terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

`checks.auto.tfvars.json` lo escribe `python3 tools/ci/generar_pipeline.py`. Al agregar un archivo de prueba: regenerar, hacer commit y volver a correr `terraform apply` para exigir el check nuevo.

## Notas

- Estado local (`terraform.tfstate`, ignorado por git). Si `manage_secrets = true`, el estado contiene los secretos: guárdalo cifrado o carga los secretos a mano en *Settings → Environments*.
- Reemplaza a los JSON `.github/ruleset-*.proposed.json`; antes de aplicar, borra los rulesets equivalentes creados a mano para no duplicarlos.
- `allowed_merge_methods` necesita el proveedor `integrations/github` 6.6 o más nuevo.
- Un check que se salta por su condición (p. ej. *revisión de dependencias del PR* en un push) cuenta como cumplido para GitHub.
