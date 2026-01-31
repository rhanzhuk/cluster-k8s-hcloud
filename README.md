# Kubernetes Cluster on Hetzner Cloud (Terraform + Ansible)

## Requirements
- Terraform >= 1.6
- Ansible
- SSH access configured
- Hetzner Cloud API token

---

## Setup

### 1. Configure Terraform variables

Create the `terraform.tfvars` file:

```bash
touch terraform.tfvars
```

Add your Hetzner Cloud token:

```hcl
hcloud_token = "<HCLOUD_TOKEN>"
```

---

### 2. Provision infrastructure

```bash
cd terraform
terraform init
terraform apply
```

---

### 3. Configure Kubernetes cluster

```bash
cd ../ansible
ansible-playbook -i inventory.ini playbooks/pre-install.yml
```

---

## Verification

```bash
kubectl get nodes
```

---

## Cleanup

```bash
cd terraform
terraform destroy
```

---

## Notes
- Do not commit `terraform.tfvars` to the repository
- Store API tokens securely
- Tested on Ubuntu 24.04
