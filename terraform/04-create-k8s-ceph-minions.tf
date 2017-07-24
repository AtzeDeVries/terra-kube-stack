### ceph-minion Nodes

variable "ceph-minion-count" { default = 1}
variable "ceph-minion-floating-ips" { default = 1 }
variable "ceph-minion-flavor-id" {}
variable "ceph-minion-sec-group" {}
variable "ceph-minion-image-id" {}


#resource "openstack_networking_port_v2" "ceph-minion-ports" {
#  count = "${var.ceph-minion-count}"
#  name = "k8s-${var.cluster-name}-ceph-minion-${count.index}"
#  network_id = "${var.internal-ip-pool-id}"
#  admin_state_up = "true"
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[0]}"
#  }
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[1]}"
#  }
#}

resource "openstack_compute_instance_v2" "ceph-minion" {
  count = "${var.ceph-minion-count}"
  name  = "k8s-${var.cluster-name}-ceph-minion-${count.index}"

  image_id        = "${var.ceph-minion-image-id}"
  flavor_id       = "${var.ceph-minion-flavor-id}"
  key_pair        = "${var.key-pair}"
  security_groups = ["${var.ceph-minion-sec-group}"]

  network {
    #port = "${element(openstack_networking_port_v2.ceph-minion-ports.*.id, count.index)}"
    name = "${var.internal-ip-pool}"
  }

#  block_device {
#    uuid                  = "${var.cronus-image-id}"
#    source_type           = "image"
#    volume_size           = 200
#    boot_index            = 0
#    destination_type      = "volume"
#    delete_on_termination = true
#  }

  user_data   = "${file("${path.module}/${var.user-data-file}")}"
}

resource "openstack_compute_floatingip_v2" "ceph-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.ceph-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "ceph-minion-flip-asso" {
  count = "${var.ceph-minion-floating-ips}"
  floating_ip = "${element(openstack_compute_floatingip_v2.ceph-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.ceph-minion.*.id,count.index)}"
}

### -> output
data "template_file" "ceph-minion" {
  count    = "${var.ceph-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-ceph-minion-${count.index}"
    #ip = "temp"
    ip        = "${element(openstack_compute_instance_v2.ceph-minion.*.access_ip_v4, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.ceph-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}


data "template_file" "ceph-port-update" {
  count    = "${var.ceph-minion-count}"
  template = "${file("${path.module}/template-port_update_single")}"
  vars {
    #node_name = "k8s-${var.cluster-name}-ceph-minion-${count.index}"
    #ip = "temp"
    instance_id = "${element(openstack_compute_instance_v2.ceph-minion.*.id, count.index)}"
    #port_id        = "${element(openstack_compute_instance_v2.ceph-minion.*.network.0.port, count.index)}"
    #ip        = "${element(openstack_compute_instance_v2.ceph-minion.*.access_ip_v4, count.index)}"
   # ip        = "${element(openstack_networking_port_v2.ceph-minion-ports.*.fixed_ip, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.ceph-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}

