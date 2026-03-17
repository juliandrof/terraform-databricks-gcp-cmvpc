# -----------------------------------------------------------------------------
# Customer-managed VPC and subnets for Databricks on GCP
# -----------------------------------------------------------------------------

resource "google_compute_network" "databricks_vpc" {
  name                    = var.vpc_name
  project                 = var.gcp_project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "databricks_subnet" {
  name                     = "${var.vpc_name}-subnet"
  project                  = var.gcp_project_id
  region                   = var.gcp_region
  network                  = google_compute_network.databricks_vpc.id
  ip_cidr_range            = var.subnet_ip_cidr_range
  private_ip_google_access = var.private_google_access

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pod_ip_cidr_range
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.service_ip_cidr_range
  }
}

# Allow internal communication between Databricks nodes
resource "google_compute_firewall" "databricks_internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.gcp_project_id
  network = google_compute_network.databricks_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_ip_cidr_range,
    var.pod_ip_cidr_range,
    var.service_ip_cidr_range,
  ]
}

# Cloud NAT for outbound internet (required if no public IPs on nodes)
resource "google_compute_router" "databricks_router" {
  name    = "${var.vpc_name}-router"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = google_compute_network.databricks_vpc.id
}

resource "google_compute_router_nat" "databricks_nat" {
  name                               = "${var.vpc_name}-nat"
  project                            = var.gcp_project_id
  router                             = google_compute_router.databricks_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
