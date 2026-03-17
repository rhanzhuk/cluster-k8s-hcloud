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

