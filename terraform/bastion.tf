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