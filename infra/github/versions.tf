terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  # Estado local por defecto (no se sube: ver .gitignore). Para trabajar en
  # equipo, mover a un backend remoto (Terraform Cloud gratuito, Azure Storage).
  backend "local" {
    path = "terraform.tfstate"
  }
}

# El token se toma de la variable de entorno GITHUB_TOKEN (nunca en archivos).
# Permisos del token fino: Administration, Environments, Secrets, Variables
# (lectura/escritura) sobre el repositorio de la app.
provider "github" {
  owner = var.owner
}
