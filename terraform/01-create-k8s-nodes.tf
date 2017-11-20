### Master Nodes

variable "master-count" { default = 1}
variable "master-floating-ips" { default = 1 }
variable "master-flavor-id" {}
#variable "master-sec-group" {}
variable "master-image-id" {}


resource "openstack_compute_servergroup_v2" "master-anti-affinity" {
  name = "k8s-master-${var.cluster-name}-anti-anffinity"
  policies = ["anti-affinity"]
}

resource "openstack_networking_port_v2" "master-ports" {
  count = "${var.master-count}"
  name = "k8s-${var.cluster-name}-master-${count.index}-port"
  network_id = "${openstack_networking_network_v2.k8s-network.id}"
  security_group_ids = ["${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}","${openstack_compute_secgroup_v2.k8s-secgroup-services.id}"]
  admin_state_up = "true"
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

resource "openstack_compute_instance_v2" "master" {
  count = "${var.master-count}"
  name  = "k8s-${var.cluster-name}-master-${count.index}"

  image_id        = "${var.master-image-id}"
  flavor_id       = "${var.master-flavor-id}"
  key_pair        = "${var.key-pair}"
  scheduler_hints {
            group = "${openstack_compute_servergroup_v2.master-anti-affinity.id}"
  }
  network {
    port = "${element(openstack_networking_port_v2.master-ports.*.id, count.index)}"
  }
  user_data   = "${file("${path.module}/${var.user-data-file}")}"
}

resource "openstack_networking_floatingip_v2" "master-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.master-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "master-flip-asso" {
  count = "${var.master-floating-ips}"
  floating_ip = "${element(openstack_networking_floatingip_v2.master-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
  fixed_ip = "${element(openstack_compute_instance_v2.master.*.network.0.fixed_ip_v4, count.index)}"
}

### -> output
data "template_file" "master" {
  count    = "${var.master-floating-ips}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-master-${count.index}"
    ip        = "${element(openstack_networking_floatingip_v2.master-flip.*.address, count.index)}"
  }
}

data "template_file" "master_noflip" {
  count    = "${var.master-count - var.master-floating-ips}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-master-${count.index + var.master-floating-ips}"
    ip        = "${element(openstack_compute_instance_v2.master.*.network.0.fixed_ip_v4, count.index + var.master-floating-ips)}"
  }
}



