variable "google_service_account_email" {
  description = "E-mail da Google Service Account usada para autenticação nos providers"
  type        = string
}

variable "gcp_project_id" {
  description = "ID do projeto GCP onde os recursos serão criados"
  type        = string
}

variable "gcp_region" {
  description = "Região GCP para o workspace Databricks"
  type        = string
  default     = "us-central1"
}

variable "databricks_account_id" {
  description = "ID da conta Databricks (encontrado no console de contas)"
  type        = string
}

variable "workspace_name" {
  description = "Nome do workspace Databricks"
  type        = string
  default     = "databricks-workspace"
}

variable "databricks_admin_user" {
  description = "E-mail do usuário admin a ser adicionado ao workspace (deve existir na conta Databricks)"
  type        = string
}

variable "subnet_ip_cidr_range" {
  description = "Range CIDR primário da subnet de compute (cada nó GCE usa 2 IPs)"
  type        = string
  default     = "10.0.0.0/20"
}
