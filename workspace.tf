# -----------------------------------------------------------------------------
# Register the customer-managed VPC as a Databricks network configuration,
# then create the workspace that uses it.
#
# Databricks on GCP uses GCE (Google Compute Engine) VMs for its compute plane.
# No GKE configuration or secondary IP ranges are needed.
# -----------------------------------------------------------------------------

resource "databricks_mws_networks" "this" {
  provider     = databricks.accounts
  account_id   = var.databricks_account_id
  network_name = "${var.workspace_name}-network"

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
