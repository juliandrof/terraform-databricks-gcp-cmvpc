output "workspace_url" {
  description = "URL do workspace Databricks"
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_id" {
  description = "ID do workspace Databricks"
  value       = databricks_mws_workspaces.this.workspace_id
}

output "network_id" {
  description = "ID da configuração de rede Databricks"
  value       = databricks_mws_networks.this.network_id
}

output "vpc_id" {
  description = "Self-link da VPC no GCP"
  value       = google_compute_network.databricks_vpc.self_link
}

output "subnet_id" {
  description = "Self-link da subnet no GCP"
  value       = google_compute_subnetwork.databricks_subnet.self_link
}
