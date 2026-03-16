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

#network

resource "hcloud_network" "main" {
  name     = "main_net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "k8s" {
  network_zone = "us-west" #"eu-central"
  type         = "server"
  ip_range     = "10.0.10.0/24"
  network_id   = hcloud_network.main.id
}

#LB for k8s
resource "hcloud_load_balancer" "k8s-api-lb" {
  name               = "k8s-api"
  load_balancer_type = "lb11"
  network_zone       = "us-west" #"eu-central"
  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "k8s-api-lb-network" {
  load_balancer_id        = hcloud_load_balancer.k8s-api-lb.id
  subnet_id               = hcloud_network_subnet.k8s.id
  ip                      = local.k8s_api_priv_ip
  enable_public_interface = false
}

resource "hcloud_load_balancer_service" "k8s-api-lb-service" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    timeout  = 10
    interval = 10
    retries  = 5
  }

}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m1" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type             = "server"
  server_id        = hcloud_server.master-1.id
  use_private_ip   = true
}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m2" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type             = "server"
  server_id        = hcloud_server.master-2.id
  use_private_ip   = true
}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m3" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type             = "server"
  server_id        = hcloud_server.master-3.id
  use_private_ip   = true
}


# servers
resource "hcloud_server" "master-1" {
  name        = "master-1"
  image       = "ubuntu-24.04"
  server_type = "cpx31" #"cx33"
  location    = "hil"   #"fsn1"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  user_data   = file("./cloud-init/cloud-init-server.yaml")
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.master_1_priv_ip
  }
}

resource "hcloud_server" "master-2" {
  name        = "master-2"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "hil"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  user_data   = file("./cloud-init/cloud-init-server.yaml")
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.master_2_priv_ip
  }
}

resource "hcloud_server" "master-3" {
  name        = "master-3"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "hil"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  user_data   = file("./cloud-init/cloud-init-server.yaml")
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.master_3_priv_ip
  }
}

resource "hcloud_server" "worker-1" {
  name        = "worker-1"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "hil"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  user_data   = file("./cloud-init/cloud-init-server.yaml")
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.worker_1_priv_ip
  }
}

resource "hcloud_server" "worker-2" {
  name        = "worker-2"
  image       = "ubuntu-24.04"
  server_type = "cpx31"
  location    = "hil"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  user_data   = file("./cloud-init/cloud-init-server.yaml")
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.worker_2_priv_ip
  }
}

#nat-server
resource "hcloud_server" "nat-server" {
  name        = "nat-server"
  server_type = "cpx11"
  image       = "ubuntu-24.04"
  location    = "hil"
  user_data   = file("./cloud-init/cloud-init-nat-server.yaml")
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.nat_priv_ip
  }
  depends_on = [hcloud_network_subnet.k8s]

}

resource "hcloud_network_route" "route_priv" {
  network_id  = hcloud_network.main.id
  destination = "0.0.0.0/0"
  gateway     = local.nat_priv_ip
}


#bastion server
resource "hcloud_server" "bastion" {
  name        = "bastion-instalation"
  server_type = "cpx11"
  image       = "ubuntu-24.04"
  location    = "hil"
  ssh_keys    = [hcloud_ssh_key.pub_key.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.main.id
    ip         = local.bastion_ip

  }
}

#firewall rule
resource "hcloud_firewall" "bastion-fw" {
  name = "bastion-fw"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "178.42.118.157/32"
    ]
  }

  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0"]
  }

}

resource "hcloud_firewall_attachment" "bastion-fw-attach" {
  firewall_id = hcloud_firewall.bastion-fw.id
  server_ids  = [hcloud_server.bastion.id]

}


resource "hcloud_firewall" "nat-fw" {
  name = "nat-fw"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = 22
    source_ips = [
    "${local.bastion_ip}/32"]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "${local.bastion_ip}/32"
    ]
  }

}

resource "hcloud_firewall_attachment" "nat-fw-attach" {
  firewall_id = hcloud_firewall.nat-fw.id
  server_ids  = [hcloud_server.nat-server.id]
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

