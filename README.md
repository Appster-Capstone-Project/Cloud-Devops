# Cloud Deployment with Terraform, GitHub Actions, and Ansible

## Overview
This repository demonstrates an **end-to-end automated cloud deployment pipeline** using:
- **Terraform** for infrastructure provisioning
- **GitHub Actions** for CI/CD automation
- **Azure** as the cloud provider
- **Ansible** for post-provisioning configuration and application deployment

The goal is to provide a **repeatable, secure, and environment-agnostic** way to deploy virtual machines and deploy/update containerized applications on them.

---

## Architecture

### 1. Terraform
- Provisions Azure resources:
  - Resource Group
  - Storage account for remote Terraform state
  - Virtual Machine (VM) with SSH and/or Azure AD authentication
  - Networking resources (VNet, Subnet, Public IP, Security Groups)

### 2. GitHub Actions
- Handles:
  - On-demand runs via `workflow_dispatch` inputs
  - Secure authentication to Azure via OIDC (no secrets in repo)
  - Dynamic environment selection (e.g., `dev`, `prod`)
  - Artifact storage for Terraform plans
  - Conditional execution for `plan`, `apply`, or `destroy`

### 3. Ansible
- Configures:
  - Docker runtime on the VM
  - Deployment of a containerized application from Azure Container Registry (ACR)
  - Auto-restart and recreation of containers when new images are pushed

---

## Deployment Flow

### 1. Triggering the Workflow
Manually trigger the workflow from GitHub Actions:
- **Action**: `plan`, `apply`, or `destroy`
- **Environment**: Target environment name (default: `dev`)


---

### 2. Backend Setup (First Time Only)
Before running `plan` or `apply`, the Terraform backend storage must exist.  
The `setup-tf-backend` job:
- Creates an Azure Resource Group
- Creates a Storage Account & Blob Container for state files
- Configures secure access (no public blob access)

> This only needs to be run **once** per project.

---

### 3. Infrastructure Provisioning
The `terraform-plan` job:
- Generates VM Ignition/Cloud-Init configuration (via **Butane**)
- Retrieves SSH private key securely from Azure Key Vault
- Logs into Azure via OIDC
- Runs `terraform init` to configure backend state
- Runs `terraform plan` to generate an execution plan
- Uploads the plan artifact

The `terraform-apply` job:
- Downloads the plan artifact
- Re-initializes Terraform
- Applies infrastructure changes (`terraform apply`)
- Retrieves VM public IP for later use

---

### 4. Application Deployment
After VM provisioning:
- Ansible connects to the VM using the retrieved SSH key
- Ensures Docker and containerd are running
- Logs into ACR securely
- Pulls the latest application image
- Deploys/recreates the container with the correct environment variables and port mappings

---

### 5. Infrastructure Destruction
The `terraform-destroy` job:
- Logs into Azure
- Runs `terraform destroy` using the same backend state
- Removes all provisioned resources

---

## Security Considerations
- **OIDC Authentication**: Avoids storing cloud credentials in GitHub
- **Key Vault Integration**: Private SSH keys are stored securely
- **Remote State**: Terraform state is stored in Azure Blob Storage
- **Minimal Secrets Exposure**: Sensitive values masked in logs



