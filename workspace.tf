# -----------------------------------------------------------------------------
# Register the customer-managed VPC as a Databricks network configuration,
# then create the workspace that uses it.
# -----------------------------------------------------------------------------

resource "databricks_mws_networks" "this" {
  provider     = databricks.accounts
  account_id   = var.databricks_account_id
  network_name = "${var.workspace_name}-network"

  gcp_network_info {
    network_project_id    = var.gcp_project_id
    vpc_id                = google_compute_network.databricks_vpc.name
    subnet_id             = google_compute_subnetwork.databricks_subnet.name
    subnet_region         = var.gcp_region
    pod_ip_range_name     = "pods"
    service_ip_range_name = "services"
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

  # GKE config is required for customer-managed VPC workspaces
  gke_config {
    connectivity_type = "PRIVATE_NODE_PUBLIC_MASTER"
    master_ip_range   = "10.3.0.0/28"
  }
}
