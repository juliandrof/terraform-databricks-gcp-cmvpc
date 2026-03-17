# -----------------------------------------------------------------------------
# Registra a VPC gerenciada pelo cliente como configuração de rede Databricks,
# cria o workspace e adiciona o usuário admin.
#
# Databricks no GCP usa VMs GCE (Google Compute Engine) no plano de compute.
# Não é necessário configuração de GKE nem ranges secundários de IP.
# -----------------------------------------------------------------------------

resource "databricks_mws_networks" "this" {
  provider     = databricks.accounts
  account_id   = var.databricks_account_id
  network_name = "databricks-network-${random_string.suffix.result}"

  gcp_network_info {
    network_project_id = var.gcp_project_id
    vpc_id             = google_compute_network.databricks_vpc.name
    subnet_id          = google_compute_subnetwork.databricks_subnet.name
    subnet_region      = var.gcp_region
  }
}

resource "databricks_mws_workspaces" "this" {
  provider       = databricks.accounts
  account_id     = var.databricks_account_id
  workspace_name = var.workspace_name
  location       = var.gcp_region

  cloud_resource_container {
    gcp {
      project_id = var.gcp_project_id
    }
  }

  network_id = databricks_mws_networks.this.network_id
}

# -----------------------------------------------------------------------------
# Configuração pós-criação: adiciona usuário admin ao workspace
# -----------------------------------------------------------------------------

data "databricks_group" "admins" {
  depends_on   = [databricks_mws_workspaces.this]
  provider     = databricks.workspace
  display_name = "admins"
}

resource "databricks_user" "admin" {
  depends_on = [databricks_mws_workspaces.this]
  provider   = databricks.workspace
  user_name  = var.databricks_admin_user
}
