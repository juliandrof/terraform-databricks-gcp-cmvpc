# Databricks Workspace on GCP — Customer-Managed VPC

Terraform configuration to deploy a **Databricks workspace on Google Cloud Platform** using a **customer-managed VPC**, giving you full control over network topology, IP ranges, and security boundaries.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  GCP Project                                                    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Customer-Managed VPC                                     │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Subnet (10.0.0.0/20)                               │  │  │
│  │  │                                                     │  │  │
│  │  │  ┌──────────────┐  ┌──────────────────────────────┐ │  │  │
│  │  │  │  GKE Nodes   │  │  Secondary Ranges            │ │  │  │
│  │  │  │  (Private)   │  │  ├─ Pods:     10.1.0.0/16    │ │  │  │
│  │  │  │              │  │  └─ Services: 10.2.0.0/20    │ │  │  │
│  │  │  └──────────────┘  └──────────────────────────────┘ │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐  │  │
│  │  │ Cloud Router  │──│  Cloud NAT   │  │   Firewall     │  │  │
│  │  │              │  │  (Outbound)  │  │  (Internal)    │  │  │
│  │  └──────────────┘  └──────────────┘  └────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Databricks Control Plane (Managed by Databricks)         │  │
│  │  ├─ MWS Network Configuration                             │  │
│  │  └─ MWS Workspace                                         │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## What's Included

| Resource | Description |
|---|---|
| **VPC** | Custom-mode VPC with no auto-created subnets |
| **Subnet** | Regional subnet with primary + secondary IP ranges (pods & services) |
| **Firewall** | Allows all internal traffic between nodes, pods, and services |
| **Cloud Router + NAT** | Outbound internet access for private GKE nodes |
| **Databricks Network** | MWS network configuration pointing to the customer VPC |
| **Databricks Workspace** | Workspace deployed with `PRIVATE_NODE_PUBLIC_MASTER` GKE config |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- A **Databricks account** on GCP with account-level admin access
- A **GCP project** with the following APIs enabled:
  - Compute Engine API
  - Kubernetes Engine API
  - Cloud Resource Manager API

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/juliandrof/terraform-databricks-gcp-cmvpc.git
cd terraform-databricks-gcp-cmvpc

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Authenticate

```bash
# GCP
gcloud auth application-default login

# Databricks account-level API
export DATABRICKS_HOST="https://accounts.gcp.databricks.com"
export DATABRICKS_TOKEN="<your-account-level-token>"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Access your workspace

After `terraform apply` completes, the workspace URL will be shown in the outputs:

```
workspace_url = "https://xxxxxxxxxxxx.gcp.databricks.com"
```

## Variables

| Name | Description | Default |
|---|---|---|
| `databricks_account_id` | Databricks account ID | — |
| `gcp_project_id` | GCP project ID | — |
| `gcp_region` | GCP region | `us-central1` |
| `workspace_name` | Workspace name | `databricks-workspace` |
| `vpc_name` | VPC name | `databricks-vpc` |
| `subnet_ip_cidr_range` | Node subnet CIDR | `10.0.0.0/20` |
| `pod_ip_cidr_range` | Pod secondary range CIDR | `10.1.0.0/16` |
| `service_ip_cidr_range` | Service secondary range CIDR | `10.2.0.0/20` |

## Outputs

| Name | Description |
|---|---|
| `workspace_url` | Databricks workspace URL |
| `workspace_id` | Databricks workspace ID |
| `network_id` | Databricks network configuration ID |
| `vpc_id` | GCP VPC self-link |
| `subnet_id` | GCP subnet self-link |

## Customization

### Full Private Connectivity

To make the GKE master private as well, change the `gke_config` in `workspace.tf`:

```hcl
gke_config {
  connectivity_type = "PRIVATE_NODE_PRIVATE_MASTER"
  master_ip_range   = "10.3.0.0/28"
}
```

> This requires additional configuration such as Private Service Connect (PSC) or VPN to reach the Databricks control plane.

### CIDR Ranges

Adjust the CIDR ranges in `terraform.tfvars` to fit your existing network topology. Ensure there are no overlaps with other VPCs if you plan to use VPC peering.

## Clean Up

```bash
terraform destroy
```

## License

MIT
