# Configuración de GitHub para la app (spec 047/048):
#  - reglas de main, develop y release/* con TODOS los checks del pipeline
#  - entornos firma, staging y production (con aprobación humana)
#  - variables y, opcionalmente, secretos del pipeline
data "github_repository" "app" {
  full_name = "${var.owner}/${var.repository}"
}

data "github_user" "reviewer" {
  for_each = toset(var.production_reviewers)
  username = each.value
}

locals {
  # 15368 = GitHub Actions: el check debe venir de Actions, no de otra app.
  actions_app_id = 15368

  branch_rules = {
    main = {
      include = ["refs/heads/main"]
      checks  = var.required_checks
    }
    develop = {
      include = ["refs/heads/develop"]
      checks  = var.required_checks
    }
    release = {
      include = ["refs/heads/release/**/*"]
      checks  = var.required_checks
    }
  }
}

resource "github_repository_ruleset" "flujo" {
  for_each    = local.branch_rules
  name        = "${each.key}-ci-completo"
  repository  = data.github_repository.app.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = each.value.include
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = var.required_approvals
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["merge"]
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      dynamic "required_check" {
        for_each = each.value.checks
        content {
          context        = required_check.value
          integration_id = local.actions_app_id
        }
      }
    }
  }
}

# --- Entornos ----------------------------------------------------------------
resource "github_repository_environment" "firma" {
  repository  = data.github_repository.app.name
  environment = "firma"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment" "staging" {
  repository  = data.github_repository.app.name
  environment = "staging"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment" "production" {
  repository          = data.github_repository.app.name
  environment         = "production"
  prevent_self_review = false

  reviewers {
    users = [for u in data.github_user.reviewer : u.id]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

locals {
  env_branches = {
    "firma-main"      = { env = github_repository_environment.firma.environment, pattern = "main" }
    "firma-release"   = { env = github_repository_environment.firma.environment, pattern = "release/*" }
    "staging-release" = { env = github_repository_environment.staging.environment, pattern = "release/*" }
    "production-main" = { env = github_repository_environment.production.environment, pattern = "main" }
  }
}

resource "github_repository_environment_deployment_policy" "ramas" {
  for_each       = local.env_branches
  repository     = data.github_repository.app.name
  environment    = each.value.env
  branch_pattern = each.value.pattern
}

# --- Variables del pipeline ----------------------------------------------------
locals {
  repo_vars = {
    FLUTTER_VERSION      = var.flutter_version
    ANDROID_PACKAGE_NAME = var.android_package_name
    API_BASE_URL         = var.api_base_url
    API_MODE             = var.api_mode
    LANDING_URL          = var.landing_url
    PLAY_STATUS          = var.play_status
    MIN_COVERAGE         = tostring(var.min_coverage)
  }
}

resource "github_actions_variable" "app" {
  for_each      = local.repo_vars
  repository    = data.github_repository.app.name
  variable_name = each.key
  value         = each.value
}

# --- Secretos (solo si manage_secrets) ----------------------------------------
locals {
  firma_secrets = var.manage_secrets ? {
    ANDROID_KEYSTORE_BASE64   = var.android_keystore_base64
    ANDROID_KEYSTORE_PASSWORD = var.android_keystore_password
    ANDROID_KEY_ALIAS         = var.android_key_alias
    ANDROID_KEY_PASSWORD      = var.android_key_password
    GOOGLE_SERVICES_JSON      = var.google_services_json
  } : {}

  play_secrets = var.manage_secrets ? {
    "staging"    = github_repository_environment.staging.environment
    "production" = github_repository_environment.production.environment
  } : {}
}

resource "github_actions_environment_secret" "firma" {
  # Llaves fijas (no sensibles); los valores sí lo son.
  for_each        = var.manage_secrets ? toset(["ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD", "GOOGLE_SERVICES_JSON"]) : toset([])
  repository      = data.github_repository.app.name
  environment     = github_repository_environment.firma.environment
  secret_name     = each.value
  plaintext_value = local.firma_secrets[each.value]
}

resource "github_actions_environment_secret" "play" {
  for_each        = local.play_secrets
  repository      = data.github_repository.app.name
  environment     = each.value
  secret_name     = "PLAY_SERVICE_ACCOUNT_JSON"
  plaintext_value = var.play_service_account_json
}
