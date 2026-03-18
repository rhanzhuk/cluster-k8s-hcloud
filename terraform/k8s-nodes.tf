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

variable "worker_count" {
  description = "Number of workers node"
  default     = 2
  type        = number

}

resource "hcloud_server" "workers" {
  count       = var.worker_count
  name        = "worker-${count.index + 1}"
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
    ip         = "10.0.10.${20 + count.index}"

  }
}



#resource "hcloud_server" "worker-1" {
#  name        = "worker-1"
#  image       = "ubuntu-24.04"
#  server_type = "cpx31"
#  location    = "hil"
#  ssh_keys    = [hcloud_ssh_key.pub_key.id]
#  user_data   = file("./cloud-init/cloud-init-server.yaml")
#  public_net {
#    ipv4_enabled = false
#    ipv6_enabled = false
#  }
#  network {
#    network_id = hcloud_network.main.id
#    ip         = local.worker_1_priv_ip
#  }
#}

#resource "hcloud_server" "worker-2" {
#  name        = "worker-2"
#  image       = "ubuntu-24.04"
#  server_type = "cpx31"
#  location    = "hil"
#  ssh_keys    = [hcloud_ssh_key.pub_key.id]
#  user_data   = file("./cloud-init/cloud-init-server.yaml")
#  public_net {
#    ipv4_enabled = false
#    ipv6_enabled = false
#  }
#  network {
#    network_id = hcloud_network.main.id
#    ip         = local.worker_2_priv_ip
#  }
#}
