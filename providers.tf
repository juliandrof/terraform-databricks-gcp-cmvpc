# Account-level Databricks provider for workspace provisioning.
# Authenticate via DATABRICKS_HOST (https://accounts.gcp.databricks.com)
# and one of: OAuth M2M (service principal), Google ID token, or PAT.
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.gcp.databricks.com"
  account_id = var.databricks_account_id
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
