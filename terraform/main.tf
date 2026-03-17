terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.56.0"
    }
  }
  required_version = ">= 1.6.0"
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

locals {
  master_1_priv_ip = "10.0.10.10"
  master_2_priv_ip = "10.0.10.11"
  master_3_priv_ip = "10.0.10.12"
  worker_1_priv_ip = "10.0.10.20"
  worker_2_priv_ip = "10.0.10.21"
  nat_priv_ip      = "10.0.10.50"
  k8s_api_priv_ip  = "10.0.10.40"
  bastion_ip       = "10.0.10.55"
}

# ssh pub key
resource "hcloud_ssh_key" "pub_key" {
  name       = "admin_pub_key"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

#outputs

output "network_id" {
  value = hcloud_network.main.id
}

output "master_private_ip" {
  value = {
    master_1 = local.master_1_priv_ip
    master_2 = local.master_2_priv_ip
    master_3 = local.master_3_priv_ip
  }
}

output "workers_private_ip" {
  value = {
    worker_1 = local.worker_1_priv_ip
    worker_2 = local.worker_2_priv_ip
  }
}

output "bastion_public_ip" {
  value = hcloud_server.bastion.ipv4_address
}

output "k8s_api_private_ip" {
  value = local.k8s_api_priv_ip
}

resource "local_file" "ansible_ini" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/../ansible/inventory.ini.tmpl", {
    bastion_ip       = hcloud_server.bastion.ipv4_address,
    k8s_api_priv_ip  = local.k8s_api_priv_ip,
    master_1_priv_ip = local.master_1_priv_ip,
    master_2_priv_ip = local.master_2_priv_ip,
    master_3_priv_ip = local.master_3_priv_ip,
    worker_1_priv_ip = local.worker_1_priv_ip,
    worker_2_priv_ip = local.worker_2_priv_ip
  })
}

resource "local_file" "ansible_playbook" {
  filename = "${path.module}/../ansible/playbooks/install-cluster-ha-k8s.yml"

  content = templatefile("${path.module}/../ansible/playbooks/install-cluster-ha-k8s.yml.tmpl", {
    network_id       = hcloud_network.main.id,
    token            = var.hcloud_token,
    master_1_priv_ip = local.master_1_priv_ip
  })
}

