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
    public_key = file("~/.ssh/id_rsa.pub")
}

#network

resource "hcloud_network" "main" {
    name = "main_net"
    ip_range = "10.98.0.0/16"
}

resource "hcloud_network_subnet" "k8s" {
    network_zone = "eu-central"
    type = "server"
    ip_range = "10.98.0.0/16"
    network_id = hcloud_network.main.id
}

resource "hcloud_server_network" "master_1" {
  server_id  = hcloud_server.master-1.id
  network_id = hcloud_network.main.id
  ip         = "10.98.0.10"
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


resource "hcloud_server" "master-1" {
    name = "master-1"
    image = "ubuntu-24.04"
    server_type = "cx23"
    location = "hel1"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
    #network {
    #  network_id = hcloud_network.main.id
    #}
    #depends_on = [ hcloud_network_subnet.k8s ]
}

resource "hcloud_server" "worker-1" {
    name = "worker-1"
    image = "ubuntu-24.04"
    server_type = "cx33"
    location = "hel1"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
#    user_data = templatefile("./cloud-init/cloud-init.yaml.tmpl", {
#        floating_ip = hcloud_floating_ip.float_ip.ipv4_address
#    })
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
    #network {
    #  network_id = hcloud_network.main.id
    #}
    #depends_on = [ hcloud_network_subnet.k8s ]
}

resource "hcloud_server" "worker-2" {
    name = "worker-2"
    image = "ubuntu-24.04"
    server_type = "cx33"
    location = "hel1"
    ssh_keys = [hcloud_ssh_key.pub_key.id]
#    user_data = templatefile("./cloud-init/cloud-init.yaml.tmpl", {
#        floating_ip = hcloud_floating_ip.float_ip.ipv4_address
#    })
    public_net {
      ipv4_enabled = true
      ipv6_enabled = false
    }
    #network {
    #  network_id = hcloud_network.main.id
    #}
    #depends_on = [ hcloud_network_subnet.k8s ]
}

output "network_id" {
    value = hcloud_network.main.id
}

output "master_private_ip" {
  value = hcloud_server_network.master_1.ip
}

output "workers_private_ip" {
  value = {
    worker_1 = hcloud_server_network.worker_1.ip
    worker_2 = hcloud_server_network.worker_2.ip
  }
}

resource "local_file" "ansible_ini" {
    filename = "${path.module}/../ansible/inventory.ini"

    content = templatefile("${path.module}/../ansible/inventory.ini.tmpl", {
        master_1_pub_ip  = hcloud_server.master-1.ipv4_address,
        worker_1_pub_ip  = hcloud_server.worker-1.ipv4_address,
        worker_2_pub_ip  = hcloud_server.worker-2.ipv4_address,
        master_1_priv_ip = hcloud_server_network.master_1.ip
    })
}

resource "local_file" "ansible_playbook" {
    filename = "${path.module}/../ansible/playbooks/pre-install.yml"

    content = templatefile("${path.module}/../ansible/playbooks/pre-install.yml.tmpl", {
        network_id = hcloud_network.main.id,
        token = var.hcloud_token,
        master_1_priv_ip = hcloud_server_network.master_1.ip
    })
}

