terraform {
  required_providers {
    hcloud = {
        source = "hetznercloud/hcloud"
        version = "~> 1.56.0"
    }
  }
  required_version = ">= 1.6.0"
}

variable "hcloud_token" {
    description = "Hetzner Cloud API token"
    type = string
    sensitive = true
}

provider "hcloud" {
    token = var.hcloud_token
}

# ssh pub key
resource "hcloud_ssh_key" "pub_key" {
    name = "admin_pub_key"
    public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
    #public_key = file("~/.ssh/id_rsa.pub")
}

#network

resource "hcloud_network" "main" {
    name = "main_net"
    ip_range = "10.98.0.0/16"
}

resource "hcloud_network_subnet" "k8s" {
    network_zone = "us-west" #"eu-central"
    type = "server"
    ip_range = "10.98.0.0/16"
    network_id = hcloud_network.main.id
}

#LB for k8s
resource "hcloud_load_balancer" "k8s-api-lb" {
  name = "k8s-api"
  load_balancer_type = "lb11"
  network_zone = "us-west" #"eu-central"
  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "k8s-api-lb-network" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  subnet_id = hcloud_network_subnet.k8s.id
  ip = "10.98.0.100"
}

resource "hcloud_load_balancer_service" "k8s-api-lb-service" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  protocol = "tcp"
  listen_port = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port = 6443
    timeout = 10
    interval = 10
    retries = 5
  }

}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m1" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type = "server"
  server_id = hcloud_server.master-1.id 
  use_private_ip = true
}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m2" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type = "server"
  server_id = hcloud_server.master-2.id 
  use_private_ip = true
}

resource "hcloud_load_balancer_target" "k8s-api-lb-target-m3" {
  load_balancer_id = hcloud_load_balancer.k8s-api-lb.id
  type = "server"
  server_id = hcloud_server.master-3.id 
  use_private_ip = true
}


# servers
resource "hcloud_server" "master-1" {
    name = "master-1"
    image = "ubuntu-24.04"
    server_type = "cpx31" #"cx33"
    location = "hil" #"fsn1"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
}

resource "hcloud_server" "master-2" {
    name = "master-2"
    image = "ubuntu-24.04"
    server_type = "cpx31"
    location = "hil"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
}

resource "hcloud_server" "master-3" {
    name = "master-3"
    image = "ubuntu-24.04"
    server_type = "cpx31"
    location = "hil"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
}

resource "hcloud_server" "worker-1" {
    name = "worker-1"
    image = "ubuntu-24.04"
    server_type = "cpx31"
    location = "hil"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
}

resource "hcloud_server" "worker-2" {
    name = "worker-2"
    image = "ubuntu-24.04"
    server_type = "cpx31"
    location = "hil"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
}


resource "hcloud_server_network" "master_1" {
  server_id  = hcloud_server.master-1.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.10"
}

resource "hcloud_server_network" "master_2" {
  server_id  = hcloud_server.master-2.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.11"
}

resource "hcloud_server_network" "master_3" {
  server_id  = hcloud_server.master-3.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.12"
}

resource "hcloud_server_network" "worker_1" {
  server_id  = hcloud_server.worker-1.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.20"
}

resource "hcloud_server_network" "worker_2" {
  server_id  = hcloud_server.worker-2.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.21"
}

output "network_id" {
    value = hcloud_network.main.id
}

output "master_private_ip" {
  value = {
    master_1 = hcloud_server_network.master_1.ip
    master_2 = hcloud_server_network.master_2.ip
    master_3 = hcloud_server_network.master_3.ip
  }
}

output "workers_private_ip" {
  value = {
    worker_1 = hcloud_server_network.worker_1.ip
    worker_2 = hcloud_server_network.worker_2.ip
  }
}

output "k8s_api_private_ip" {
  value = hcloud_load_balancer_network.k8s-api-lb-network.ip
}

resource "local_file" "ansible_ini" {
    filename = "${path.module}/../ansible/inventory.ini"

    content = templatefile("${path.module}/../ansible/inventory.ini.tmpl", {
        master_1_pub_ip  = hcloud_server.master-1.ipv4_address,
        master_2_pub_ip  = hcloud_server.master-2.ipv4_address,
        master_3_pub_ip  = hcloud_server.master-3.ipv4_address,
        worker_1_pub_ip  = hcloud_server.worker-1.ipv4_address,
        worker_2_pub_ip  = hcloud_server.worker-2.ipv4_address,
        master_1_priv_ip = hcloud_server_network.master_1.ip,
        master_2_priv_ip = hcloud_server_network.master_2.ip,
        master_3_priv_ip = hcloud_server_network.master_3.ip
    })
}

resource "local_file" "ansible_playbook" {
    filename = "${path.module}/../ansible/playbooks/install-cluster-ha-k8s.yml"

    content = templatefile("${path.module}/../ansible/playbooks/install-cluster-ha-k8s.yml.tmpl", {
        network_id = hcloud_network.main.id,
        token = var.hcloud_token,
        master_1_priv_ip = hcloud_server_network.master_1.ip
    })
}
