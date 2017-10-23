### ceph-minion Nodes

variable "ceph-minion-count" { default = 1}
variable "ceph-minion-floating-ips" { default = 1 }
variable "ceph-minion-flavor-id" {}
variable "ceph-minion-sec-group" {}
variable "ceph-minion-image-id" {}

resource "openstack_networking_port_v2" "ceph-minion-ports" {
  count = "${var.ceph-minion-count}"
  name = "k8s-${var.cluster-name}-ceph-minion-${count.index}-port"
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

resource "openstack_compute_instance_v2" "ceph-minion" {
  count = "${var.ceph-minion-count}"
  name  = "k8s-${var.cluster-name}-ceph-minion-${count.index}"

  image_id        = "${var.ceph-minion-image-id}"
  flavor_id       = "${var.ceph-minion-flavor-id}"
  key_pair        = "${var.key-pair}"

  network {
    port = "${element(openstack_networking_port_v2.ceph-minion-ports.*.id, count.index)}"
  }
  user_data   = "${file("${path.module}/${var.user-data-file}")}"
}

resource "openstack_networking_floatingip_v2" "ceph-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.ceph-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "ceph-minion-flip-asso" {
  count = "${var.ceph-minion-floating-ips}"
  floating_ip = "${element(openstack_networking_floatingip_v2.ceph-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.ceph-minion.*.id,count.index)}"
}

### -> output
data "template_file" "ceph-minion" {
  count    = "${var.ceph-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-ceph-minion-${count.index}"
    ip        = "${element(openstack_compute_instance_v2.ceph-minion.*.network.0.fixed_ip_v4, count.index)}"
  }
}
