variable "databricks_account_id" {
  description = "Databricks account ID (found in the Databricks account console)"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the Databricks workspace"
  type        = string
  default     = "us-central1"
}

variable "workspace_name" {
  description = "Name of the Databricks workspace"
  type        = string
  default     = "databricks-workspace"
}

variable "vpc_name" {
  description = "Name of the customer-managed VPC"
  type        = string
  default     = "databricks-vpc"
}

variable "subnet_ip_cidr_range" {
  description = "Primary IP CIDR range for the GKE nodes subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pod_ip_cidr_range" {
  description = "Secondary IP CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_ip_cidr_range" {
  description = "Secondary IP CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/20"
}

variable "private_google_access" {
  description = "Enable Private Google Access on the subnet"
  type        = bool
  default     = true
}
