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