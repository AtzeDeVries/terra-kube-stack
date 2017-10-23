### fat-minion Nodes

variable "fat-minion-count" { default = 1}
variable "fat-minion-floating-ips" { default = 1 }
variable "fat-minion-flavor-id" {}
variable "fat-minion-sec-group" {}
variable "fat-minion-image-id" {}

resource "openstack_compute_servergroup_v2" "fat-minion-anti-affinity" {
  name = "k8s-fat-minion-${var.cluster-name}-anti-anffinity"
  policies = ["anti-affinity"]
}

resource "openstack_networking_port_v2" "fat-minion-ports" {
  count = "${var.fat-minion-count}"
  name = "k8s-${var.cluster-name}-fat-minion-${count.index}-port"
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

resource "openstack_compute_instance_v2" "fat-minion" {
  count = "${var.fat-minion-count}"
  name  = "k8s-${var.cluster-name}-fat-minion-${count.index}"

  image_id        = "${var.fat-minion-image-id}"
  flavor_id       = "${var.fat-minion-flavor-id}"
  key_pair        = "${var.key-pair}"
  scheduler_hints {
            group = "${openstack_compute_servergroup_v2.fat-minion-anti-affinity.id}"
  }

  network {
    port = "${element(openstack_networking_port_v2.fat-minion-ports.*.id, count.index)}"
  }
  user_data   = "${file("${path.module}/${var.user-data-file}")}"
}

resource "openstack_networking_floatingip_v2" "fat-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.fat-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "fat-minion-flip-asso" {
  count = "${var.fat-minion-floating-ips}"
  floating_ip = "${element(openstack_networking_floatingip_v2.fat-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.fat-minion.*.id,count.index)}"
}

### -> output
data "template_file" "fat-minion" {
  count    = "${var.fat-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-fat-minion-${count.index}"
    ip        = "${element(openstack_compute_instance_v2.fat-minion.*.network.0.fixed_ip_v4, count.index)}"
  }
}


#data "template_file" "fat-port-update" {
#  count    = "${var.fat-minion-count}"
#  template = "${file("${path.module}/template-port_update_single")}"
#  vars {
#    instance_id = "${element(openstack_compute_instance_v2.fat-minion.*.id, count.index)}"
#    subnet_0 = "${var.allowed_address_pairs_0}"
#    subnet_1 = "${var.allowed_address_pairs_1}"
#  }
#}

