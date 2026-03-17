output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_id" {
  description = "Databricks workspace ID"
  value       = databricks_mws_workspaces.this.workspace_id
}

output "network_id" {
  description = "Databricks network configuration ID"
  value       = databricks_mws_networks.this.network_id
}

output "vpc_id" {
  description = "GCP VPC self-link"
  value       = google_compute_network.databricks_vpc.self_link
}

output "subnet_id" {
  description = "GCP subnet self-link"
  value       = google_compute_subnetwork.databricks_subnet.self_link
}
