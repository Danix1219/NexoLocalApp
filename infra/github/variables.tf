variable "owner" {
  description = "Usuario u organización dueña del repositorio."
  type        = string
  default     = "Danix1219"
}

variable "repository" {
  description = "Repositorio de la app."
  type        = string
  default     = "NexoLocalApp"
}

variable "required_checks" {
  description = "Checks que deben pasar antes de fusionar. Lo genera tools/ci/generar_pipeline.py en checks.auto.tfvars.json."
  type        = list(string)
}

variable "required_approvals" {
  description = "Aprobaciones humanas por PR. 0 mientras no haya segundo revisor (docs/flujo-git.md); subir a 1 al incorporarlo."
  type        = number
  default     = 0
}

variable "production_reviewers" {
  description = "Usuarios de GitHub que aprueban la publicación en producción de Play Store."
  type        = list(string)
  default     = ["Danix1219"]
}

variable "flutter_version" {
  type    = string
  default = "3.29.3"
}

variable "android_package_name" {
  type    = string
  default = "mx.nexolocal.nexo_app"
}

variable "api_base_url" {
  description = "Backend para APK de prueba y AAB de release (solo https)."
  type        = string
  default     = "https://nexolocal-ekfpbudfewd4g0cp.northcentralus-01.azurewebsites.net"

  validation {
    condition     = startswith(var.api_base_url, "https://") && !endswith(var.api_base_url, "/")
    error_message = "api_base_url debe ser https:// y sin / al final."
  }
}

variable "api_mode" {
  description = "Modo de los grupos de endpoints en release: auto | live | fake (spec 045)."
  type        = string
  default     = "auto"

  validation {
    condition     = contains(["auto", "live", "fake"], var.api_mode)
    error_message = "api_mode debe ser auto, live o fake."
  }
}

variable "landing_url" {
  description = "Landing con /privacidad, /terminos y /eliminar-cuenta (requisitos 16 y 17). Obligatoria para el AAB."
  type        = string
  default     = ""

  validation {
    condition     = var.landing_url == "" || (startswith(var.landing_url, "https://") && !endswith(var.landing_url, "/"))
    error_message = "landing_url debe ser https:// y sin / al final."
  }
}

variable "play_status" {
  description = "Estado de la versión subida a Play: draft mientras la app no esté publicada; completed después."
  type        = string
  default     = "draft"
}

variable "min_coverage" {
  description = "Cobertura mínima de la capa lógica (constitución §8)."
  type        = number
  default     = 45
}

# --- Secretos (opcional) -----------------------------------------------------
# Si manage_secrets = true, Terraform los carga desde TF_VAR_* y quedan en el
# estado: guárdalo cifrado. Si es false, cárgalos a mano en Settings → Environments.
variable "manage_secrets" {
  type    = bool
  default = false
}

variable "android_keystore_base64" {
  type      = string
  default   = ""
  sensitive = true
}

variable "android_keystore_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "android_key_alias" {
  type      = string
  default   = "upload"
  sensitive = true
}

variable "android_key_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "google_services_json" {
  description = "Contenido de google-services.json (Firebase, push). Va al entorno firma."
  type        = string
  default     = ""
  sensitive   = true
}

variable "play_service_account_json" {
  type      = string
  default   = ""
  sensitive = true
}
