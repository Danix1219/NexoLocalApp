output "rulesets" {
  description = "Reglas creadas por rama."
  value       = { for k, r in github_repository_ruleset.flujo : k => r.ruleset_id }
}

output "checks_requeridos" {
  description = "Cantidad de checks que deben pasar para fusionar."
  value       = length(var.required_checks)
}

output "entornos" {
  value = [
    github_repository_environment.firma.environment,
    github_repository_environment.staging.environment,
    github_repository_environment.production.environment,
  ]
}
