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