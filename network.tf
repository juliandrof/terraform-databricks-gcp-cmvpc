# -----------------------------------------------------------------------------
# VPC e subnet gerenciados pelo cliente para Databricks no GCP (compute GCE)
# -----------------------------------------------------------------------------

data "google_client_openid_userinfo" "me" {}
data "google_client_config" "current" {}

# Sufixo aleatório para evitar colisão de nomes ao executar múltiplas vezes
resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 3
}

resource "google_compute_network" "databricks_vpc" {
  name                    = "databricks-vpc-${random_string.suffix.result}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "databricks_subnet" {
  name          = "databricks-subnet-${random_string.suffix.result}"
  region        = var.gcp_region
  network       = google_compute_network.databricks_vpc.id
  ip_cidr_range = var.subnet_ip_cidr_range
}

# Cloud NAT para acesso à internet (obrigatório — VMs GCE não possuem IP público)
resource "google_compute_router" "databricks_router" {
  name    = "databricks-router-${random_string.suffix.result}"
  region  = var.gcp_region
  network = google_compute_network.databricks_vpc.id
}

resource "google_compute_router_nat" "databricks_nat" {
  name                               = "databricks-nat-${random_string.suffix.result}"
  router                             = google_compute_router.databricks_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
