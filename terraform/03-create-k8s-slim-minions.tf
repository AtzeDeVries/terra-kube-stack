### slim-minion Nodes

variable "slim-minion-count" { default = 1}
variable "slim-minion-floating-ips" { default = 1 }
variable "slim-minion-flavor-id" {}
variable "slim-minion-sec-group" {}
variable "slim-minion-image-id" {}

resource "openstack_networking_port_v2" "slim-minion-ports" {
  count = "${var.slim-minion-count}"
  name = "k8s-${var.cluster-name}-slim-minion-${count.index}-port"
  network_id = "${openstack_networking_network_v2.k8s-network.id}"
  admin_state_up = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}","${openstack_compute_secgroup_v2.k8s-secgroup-services.id}"]
  fixed_ip {
    subnet_id = "${openstack_networking_subnet_v2.k8s-network-subnet.id}"
  }
  allowed_address_pairs {
    ip_address = "${var.allowed_address_pairs_0}"
  }
  allowed_address_pairs {
    ip_address = "${var.allowed_address_pairs_1}"
  }
}

resource "openstack_compute_instance_v2" "slim-minion" {
  count = "${var.slim-minion-count}"
  name  = "k8s-${var.cluster-name}-slim-minion-${count.index}"

  image_id        = "${var.slim-minion-image-id}"
  flavor_id       = "${var.slim-minion-flavor-id}"
  key_pair        = "${var.key-pair}"

  network {
    port = "${element(openstack_networking_port_v2.slim-minion-ports.*.id, count.index)}"
  }
  user_data   = "${file("${path.module}/${var.user-data-file}")}"
}

resource "openstack_networking_floatingip_v2" "slim-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.slim-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "slim-minion-flip-asso" {
  count = "${var.slim-minion-floating-ips}"
  floating_ip = "${element(openstack_networking_floatingip_v2.slim-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.slim-minion.*.id,count.index)}"
}

### -> output
data "template_file" "slim-minion" {
  count    = "${var.slim-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-slim-minion-${count.index}"
    ip        = "${element(openstack_compute_instance_v2.slim-minion.*.network.0.fixed_ip_v4, count.index)}"
  }
}
