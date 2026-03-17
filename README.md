<p align="center">
  <img src="images/architecture.png" alt="Diagrama de Arquitetura" width="800"/>
</p>

<h1 align="center">Workspace Databricks no GCP<br/>VPC Gerenciada pelo Cliente</h1>

<p align="center">
  <strong>Configuração Terraform para provisionar um workspace Databricks no Google Cloud Platform usando uma VPC gerenciada pelo cliente com compute baseado em GCE, garantindo controle total sobre topologia de rede, ranges de IP e perímetros de segurança.</strong>
</p>

<p align="center">
  <a href="#arquitetura">Arquitetura</a> •
  <a href="#o-que-é-criado">O que é criado</a> •
  <a href="#pré-requisitos">Pré-requisitos</a> •
  <a href="#passo-a-passo">Passo a passo</a> •
  <a href="#variáveis">Variáveis</a> •
  <a href="#personalização">Personalização</a>
</p>

---

## Arquitetura

<p align="center">
  <img src="images/architecture.png" alt="Visão Geral da Arquitetura" width="800"/>
</p>

O Databricks no GCP utiliza **Google Compute Engine (GCE)** para seu plano de compute. Esta configuração cria uma **VPC gerenciada pelo cliente** no seu projeto GCP e provisiona um workspace Databricks que executa todos os nós de compute como VMs GCE dentro da sua VPC — **sem IPs públicos**.

> **Nota:** O Databricks anteriormente usava GKE (Google Kubernetes Engine) no GCP. A partir de 2024, todos os novos workspaces utilizam **compute baseado em GCE**, que oferece rede mais simples (sem ranges secundários para pods/services) e inicialização de clusters mais rápida.

## O que é criado

| Recurso | Descrição |
|---|---|
| **VPC** | VPC custom-mode sem subnets automáticas |
| **Subnet** | Subnet regional com um único range primário de IP para nós GCE |
| **Cloud Router + NAT** | Acesso à internet de saída para VMs GCE privadas |
| **Rede Databricks** | Configuração de rede MWS apontando para a VPC do cliente |
| **Workspace Databricks** | Workspace provisionado com compute GCE na sua VPC |
| **Usuário Admin** | Usuário administrador adicionado ao workspace após criação |

> **Nota:** Não é criada regra de firewall explícita — o Databricks gerencia suas próprias regras de firewall na VPC durante o provisionamento do workspace.

> **Nota:** Todos os nomes de recursos incluem um **sufixo aleatório de 3 caracteres** para evitar colisão de nomes ao executar múltiplas vezes no mesmo projeto.

### Layout de Rede

<p align="center">
  <img src="images/network.png" alt="Diagrama de Rede CIDR" width="700"/>
</p>

Com compute baseado em GCE, a rede é simples — você precisa apenas de **um range de subnet primário**. Cada nó de compute Databricks utiliza **2 endereços IP** da subnet.

| CIDR da Subnet | IPs Disponíveis | Máximo de Nós Simultâneos |
|---|---|---|
| `/25` | 126 | ~60 |
| `/24` | 254 | ~120 |
| `/23` | 510 | ~250 |
| `/22` | 1.022 | ~500 |
| `/21` | 2.046 | ~1.000 |
| `/20` | 4.094 | ~2.000 |

> **Dica:** O padrão `/20` suporta até ~2.000 nós de compute simultâneos. Para cargas menores, um `/24` ou `/23` pode ser suficiente.

---

## Pré-requisitos

Antes de começar, você precisa ter:

- Um **projeto GCP** com faturamento habilitado
- Uma **conta Databricks** no GCP com acesso de **admin de conta**
- Seu **Databricks Account ID** (encontrado no [console de contas](https://accounts.gcp.databricks.com))
- Uma **Google Service Account (GSA)** com permissões para criar recursos de rede

---

## Fluxo de Deploy

<p align="center">
  <img src="images/workflow.png" alt="Fluxo de Deploy" width="600"/>
</p>

---

## Passo a passo

### Passo 1 — Instalar o Terraform

<details>
<summary><strong>macOS</strong></summary>

#### Opção A: Usando Homebrew (recomendado)

```bash
# Instalar o Homebrew se não tiver
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar o Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verificar instalação
terraform -version
```

#### Opção B: Download manual

```bash
# Baixar o binário (Apple Silicon)
curl -LO https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_darwin_arm64.zip

# Para Macs Intel, use:
# curl -LO https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_darwin_amd64.zip

# Descompactar e mover para o PATH
unzip terraform_*.zip
sudo mv terraform /usr/local/bin/
rm terraform_*.zip

# Verificar
terraform -version
```

</details>

<details>
<summary><strong>Windows</strong></summary>

#### Opção A: Usando Chocolatey (recomendado)

```powershell
# Abrir PowerShell como Administrador

# Instalar o Chocolatey se não tiver
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalar o Terraform
choco install terraform -y

# Reiniciar o terminal, depois verificar
terraform -version
```

#### Opção B: Usando winget

```powershell
winget install Hashicorp.Terraform

# Reiniciar o terminal, depois verificar
terraform -version
```

#### Opção C: Download manual

1. Baixe em [terraform.io/downloads](https://developer.hashicorp.com/terraform/downloads)
2. Extraia o arquivo `terraform.exe`
3. Mova para um diretório no seu `PATH` (ex: `C:\terraform\`)
4. Adicione o diretório ao PATH do sistema:
   ```powershell
   # PowerShell (executar como Administrador)
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\terraform", "Machine")
   ```
5. Reinicie o terminal e verifique: `terraform -version`

</details>

---

### Passo 2 — Instalar o Google Cloud SDK (`gcloud`)

<details>
<summary><strong>macOS</strong></summary>

#### Usando Homebrew

```bash
brew install --cask google-cloud-sdk

# Inicializar o gcloud
gcloud init
```

#### Instalação manual

```bash
# Baixar e executar o instalador
curl https://sdk.cloud.google.com | bash

# Reiniciar o shell
exec -l $SHELL

# Inicializar
gcloud init
```

</details>

<details>
<summary><strong>Windows</strong></summary>

#### Usando o instalador (recomendado)

1. Baixe o instalador em [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install#windows)
2. Execute `GoogleCloudSDKInstaller.exe`
3. Siga os prompts (mantenha os padrões)
4. O instalador abrirá um terminal — execute `gcloud init` quando solicitado

#### Usando PowerShell

```powershell
# Baixar e executar
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe
```

</details>

---

### Passo 3 — Habilitar APIs obrigatórias no GCP

Execute estes comandos para habilitar as APIs que o Databricks necessita no seu projeto GCP:

<details>
<summary><strong>macOS / Windows (mesmos comandos)</strong></summary>

```bash
# Definir o projeto
gcloud config set project SEU_PROJECT_ID

# Habilitar APIs obrigatórias
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable iam.googleapis.com
```

</details>

---

### Passo 4 — Criar e configurar Service Accounts

A autenticação usa **Google Service Account** com impersonação — sem PAT tokens de longa duração.

<details>
<summary><strong>Configuração básica (rápida)</strong></summary>

Use uma Service Account existente com `roles/Owner` no projeto:

```bash
# Definir o projeto
gcloud config set project SEU_PROJECT_ID

# Configurar impersonação da Service Account
gcloud config set auth/impersonate_service_account SUA_SA@SEU_PROJETO.iam.gserviceaccount.com

# Gerar token de acesso
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

</details>

<details>
<summary><strong>Configuração recomendada (com menor privilégio)</strong></summary>

Para ambientes de produção, crie duas Service Accounts separadas:

#### 1. Criar a `caller-sa` (baixo privilégio)

```bash
gcloud iam service-accounts create caller-sa \
  --display-name="Caller Service Account"

# Conceder role de Token Creator
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:caller-sa@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

#### 2. Criar a `privileged-sa` (permissões de provisionamento)

```bash
gcloud iam service-accounts create privileged-sa \
  --display-name="Privileged Service Account"
```

#### 3. Criar role customizada com permissões mínimas

```bash
cat << 'EOF' > databricks-admin-role.yaml
title: "Databricks Admin"
description: "Role customizada com permissões para criação de workspace Databricks"
stage: "GA"
includedPermissions:
- iam.roles.get
- iam.roles.create
- iam.roles.delete
- iam.roles.update
- iam.serviceAccounts.getIamPolicy
- iam.serviceAccounts.setIamPolicy
- resourcemanager.projects.get
- resourcemanager.projects.getIamPolicy
- resourcemanager.projects.setIamPolicy
- serviceusage.services.enable
- serviceusage.services.get
- serviceusage.services.list
- compute.networks.get
- compute.networks.create
- compute.networks.updatePolicy
- compute.subnetworks.get
- compute.subnetworks.create
- compute.subnetworks.getIamPolicy
- compute.subnetworks.setIamPolicy
- compute.routers.get
- compute.routers.create
- compute.routers.delete
- compute.routers.update
- compute.projects.get
- compute.firewalls.get
- compute.firewalls.create
- iam.serviceAccountKeys.create
- iam.serviceAccounts.get
- iam.serviceAccounts.update
- iam.serviceAccounts.delete
EOF

gcloud iam roles create DatabricksAdmin \
  --project=SEU_PROJECT_ID \
  --file=databricks-admin-role.yaml

# Vincular a role à privileged-sa
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:privileged-sa@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="projects/SEU_PROJECT_ID/roles/DatabricksAdmin"
```

#### 4. Autenticar com impersonação

```bash
# Baixar a chave da caller-sa
gcloud iam service-accounts keys create caller-sa-key.json \
  --iam-account=caller-sa@SEU_PROJECT_ID.iam.gserviceaccount.com

# Ativar autenticação
gcloud auth activate-service-account --key-file=caller-sa-key.json

# Configurar impersonação da privileged-sa
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/caller-sa-key.json"
gcloud config set auth/impersonate_service_account privileged-sa@SEU_PROJECT_ID.iam.gserviceaccount.com

# Gerar token
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

</details>

#### Adicionar a Service Account ao Databricks

1. Acesse [accounts.gcp.databricks.com](https://accounts.gcp.databricks.com)
2. Faça login com suas credenciais de admin
3. [Adicione](https://docs.gcp.databricks.com/administration-guide/users-groups/users.html#add-users-to-your-account-using-the-account-console) a Service Account (`privileged-sa` ou a SA que escolheu) como usuário da conta
4. [Atribua](https://docs.gcp.databricks.com/administration-guide/users-groups/users.html#assign-account-admin-roles-to-a-user) a role de **admin de conta** à Service Account

---

### Passo 5 — Clonar este repositório

<details>
<summary><strong>macOS</strong></summary>

```bash
git clone https://github.com/juliandrof/terraform-databricks-gcp-cmvpc.git
cd terraform-databricks-gcp-cmvpc
```

</details>

<details>
<summary><strong>Windows</strong></summary>

```powershell
git clone https://github.com/juliandrof/terraform-databricks-gcp-cmvpc.git
cd terraform-databricks-gcp-cmvpc
```

> **Não tem Git?** Instale: `winget install Git.Git` ou baixe em [git-scm.com](https://git-scm.com/download/win)

</details>

---

### Passo 6 — Configurar variáveis

```bash
# Copiar o arquivo de exemplo
cp terraform.tfvars.example terraform.tfvars
```

No Windows (PowerShell):
```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edite o `terraform.tfvars` com seus valores:

```hcl
google_service_account_email = "privileged-sa@meu-projeto.iam.gserviceaccount.com"
gcp_project_id               = "meu-projeto-gcp"
gcp_region                   = "us-central1"

databricks_account_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Do console de contas
workspace_name          = "meu-workspace-databricks"
databricks_admin_user   = "admin@minhaempresa.com"

# Cada nó GCE usa 2 IPs — /20 suporta ~2.000 nós simultâneos
subnet_ip_cidr_range = "10.0.0.0/20"
```

Alternativamente, passe as variáveis via CLI:

```bash
terraform plan \
  -var 'google_service_account_email=sa@projeto.iam.gserviceaccount.com' \
  -var 'gcp_project_id=meu-projeto' \
  -var 'gcp_region=us-central1' \
  -var 'databricks_account_id=xxxx-xxxx-xxxx' \
  -var 'workspace_name=meu-workspace' \
  -var 'databricks_admin_user=admin@empresa.com' \
  -var 'subnet_ip_cidr_range=10.0.0.0/20'
```

---

### Passo 7 — Inicializar o Terraform

Este comando baixa os providers necessários (Databricks + Google + Random).

```bash
terraform init
```

Saída esperada:
```
Initializing the backend...
Initializing provider plugins...
- Installing databricks/databricks...
- Installing hashicorp/google...
- Installing hashicorp/random...

Terraform has been successfully initialized!
```

---

### Passo 8 — Revisar o plano

```bash
terraform plan
```

Isso mostra **exatamente** o que o Terraform vai criar. Revise a saída:

```
Plan: 8 to add, 0 to change, 0 to destroy.
```

Você deve ver estes recursos:
- `random_string.suffix`
- `google_compute_network.databricks_vpc`
- `google_compute_subnetwork.databricks_subnet`
- `google_compute_router.databricks_router`
- `google_compute_router_nat.databricks_nat`
- `databricks_mws_networks.this`
- `databricks_mws_workspaces.this`
- `databricks_user.admin`

> Se algo não parecer correto, volte ao Passo 6 e ajuste seu `terraform.tfvars`.

---

### Passo 9 — Provisionar

```bash
terraform apply
```

Digite `yes` quando solicitado para confirmar.

> **Isso leva de 5 a 15 minutos.** O Terraform cria a VPC e recursos de rede primeiro, depois provisiona o workspace Databricks que configura o plano de compute GCE na sua VPC e adiciona o usuário admin.

Saída final esperada:
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

workspace_url = "https://xxxxxxxxxxxx.gcp.databricks.com"
workspace_id  = "1234567890123456"
network_id    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
vpc_id        = "projects/meu-projeto/global/networks/databricks-vpc-a3f"
subnet_id     = "projects/meu-projeto/regions/us-central1/subnetworks/databricks-subnet-a3f"
```

---

### Passo 10 — Acessar o workspace

Abra a `workspace_url` dos outputs no navegador. Você pode consultar a qualquer momento:

```bash
terraform output workspace_url
```

---

## Validação

Após o `apply`, valide que tudo foi criado corretamente:

```bash
# Terraform — deve mostrar nenhuma mudança pendente
terraform validate
terraform plan

# Recursos de rede no GCP
gcloud compute networks list --filter="name~^databricks-vpc-" --project SEU_PROJECT_ID
gcloud compute networks subnets list --filter="name~^databricks-subnet-" --regions SUA_REGIAO --project SEU_PROJECT_ID
gcloud compute routers list --filter="name~^databricks-router-" --regions SUA_REGIAO --project SEU_PROJECT_ID

# URL do workspace
terraform output -raw workspace_url
```

Abra a URL no navegador e verifique se o workspace carrega e se o usuário admin aparece no console de administração do workspace.

---

## Variáveis

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|---|---|---|---|---|
| `google_service_account_email` | E-mail da Google Service Account | `string` | — | Sim |
| `gcp_project_id` | ID do projeto GCP | `string` | — | Sim |
| `gcp_region` | Região GCP | `string` | `us-central1` | Não |
| `databricks_account_id` | ID da conta Databricks | `string` | — | Sim |
| `workspace_name` | Nome do workspace | `string` | `databricks-workspace` | Não |
| `databricks_admin_user` | E-mail do usuário admin | `string` | — | Sim |
| `subnet_ip_cidr_range` | CIDR da subnet (2 IPs por nó) | `string` | `10.0.0.0/20` | Não |

## Saídas (Outputs)

| Nome | Descrição |
|---|---|
| `workspace_url` | URL do workspace Databricks |
| `workspace_id` | ID do workspace Databricks |
| `network_id` | ID da configuração de rede Databricks |
| `vpc_id` | Self-link da VPC no GCP |
| `subnet_id` | Self-link da subnet no GCP |

---

## Personalização

### Ranges CIDR

Ajuste o CIDR da subnet no `terraform.tfvars` conforme sua topologia de rede existente. Com compute GCE, você precisa apenas de **um range de subnet** — sem ranges secundários para pods ou services.

Garanta que **não haja sobreposição** com outras VPCs se você planeja usar VPC peering.

### Regiões GCP Disponíveis

Algumas regiões comuns para Databricks no GCP:

| Região | Localização |
|---|---|
| `us-central1` | Iowa, EUA |
| `us-east4` | Virgínia, EUA |
| `us-west1` | Oregon, EUA |
| `europe-west1` | Bélgica |
| `europe-west3` | Frankfurt |
| `asia-southeast1` | Singapura |
| `southamerica-east1` | São Paulo, Brasil |

### Private Service Connect (PSC)

Para conectividade totalmente privada (sem caminho público para o plano de controle Databricks), você pode configurar o Private Service Connect. Isso requer recursos Terraform adicionais — consulte a [documentação de PSC do Databricks](https://docs.gcp.databricks.com/en/security/network/classic/private-service-connect.html).

---

## Resolução de Problemas

| Problema | Solução |
|---|---|
| `Error: Permission denied` no GCP | Verifique se a Service Account possui as roles corretas no projeto (Owner ou a role customizada DatabricksAdmin) |
| `Error: Account API unauthorized` | Verifique se a Service Account foi adicionada como admin de conta no console Databricks |
| `Error: CIDR range conflict` | Altere o CIDR da subnet no `terraform.tfvars` para evitar sobreposição com subnets existentes |
| `Error: API not enabled` | Execute os comandos `gcloud services enable` do Passo 3 |
| `terraform init` falha | Verifique sua conexão com a internet. Se estiver atrás de proxy, defina `HTTP_PROXY` e `HTTPS_PROXY` |
| Workspace travado no provisionamento | Pode levar até 15 minutos. Se ultrapassar 30 minutos, verifique o console de contas Databricks |
| Token expirado | Execute novamente: `export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)` |

---

## Destruição (Teardown)

Para destruir todos os recursos criados:

```bash
terraform destroy
```

Digite `yes` quando solicitado.

> **Atenção:** Isso vai excluir permanentemente o workspace Databricks e todos os dados dentro dele.

### Se o `terraform destroy` falhar com erro "VPC already being used"

Isso acontece porque o Databricks cria regras de firewall próprias na sua VPC durante o provisionamento. Essas regras precisam ser removidas antes de excluir a VPC.

#### 1. Destruir na ordem de dependência

```bash
terraform destroy -target=databricks_mws_workspaces.this
terraform destroy -target=google_compute_router_nat.databricks_nat -target=google_compute_router.databricks_router
terraform destroy
```

#### 2. Se a VPC ainda estiver "in use", limpar recursos dependentes manualmente

```bash
# Listar e excluir regras de firewall criadas pelo Databricks
gcloud compute firewall-rules list --filter="network~^databricks-vpc-" --project SEU_PROJECT_ID
gcloud compute firewall-rules delete NOME_DA_REGRA --project SEU_PROJECT_ID

# Listar e excluir routers/NAT residuais
gcloud compute routers list --filter="name~^databricks-router-" --regions SUA_REGIAO --project SEU_PROJECT_ID
gcloud compute routers nats delete NOME_NAT --router NOME_ROUTER --region SUA_REGIAO --project SEU_PROJECT_ID
gcloud compute routers delete NOME_ROUTER --region SUA_REGIAO --project SEU_PROJECT_ID

# Listar e excluir subnets residuais
gcloud compute networks subnets list --filter="network~^databricks-vpc-" --regions SUA_REGIAO --project SEU_PROJECT_ID
gcloud compute networks subnets delete NOME_SUBNET --region SUA_REGIAO --project SEU_PROJECT_ID
```

#### 3. Executar novamente

```bash
terraform destroy
```

---

## Estrutura de Arquivos

```
terraform-databricks-gcp-cmvpc/
├── images/
│   ├── architecture.png       # Diagrama de arquitetura
│   ├── network.png            # Diagrama de rede/CIDR
│   └── workflow.png           # Diagrama do fluxo de deploy
├── network.tf                 # VPC, subnet, Cloud Router, NAT
├── workspace.tf               # Rede Databricks + workspace + usuário admin
├── providers.tf               # Configuração dos providers
├── variables.tf               # Variáveis de entrada
├── outputs.tf                 # Valores de saída
├── versions.tf                # Versões do Terraform e providers
├── terraform.tfvars.example   # Valores de exemplo
├── .gitignore                 # Ignora .terraform, state, secrets
└── README.md                  # Este arquivo
```

---

## Licença

MIT
