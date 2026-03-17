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