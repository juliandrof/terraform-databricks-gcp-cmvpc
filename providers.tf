# Provider Google — usa o projeto e região definidos nas variáveis.
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Provider Databricks (account-level) — para provisionamento de workspace.
# Autenticação via Google Service Account OAuth (sem PAT tokens).
provider "databricks" {
  alias                  = "accounts"
  host                   = "https://accounts.gcp.databricks.com"
  google_service_account = var.google_service_account_email
}

# Provider Databricks (workspace-level) — para configuração pós-criação.
provider "databricks" {
  alias                  = "workspace"
  host                   = databricks_mws_workspaces.this.workspace_url
  google_service_account = var.google_service_account_email
}
