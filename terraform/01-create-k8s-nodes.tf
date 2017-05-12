### Master Nodes

variable "master-count" { default = 1}
variable "master-floating-ips" { default = 1 }
variable "master-flavor-id" {}
variable "master-sec-group" {}
variable "master-image-id" {}



#resource "openstack_networking_port_v2" "master-ports" {
#  count = "${var.master-count}"
#  name = "k8s-${var.cluster-name}-master-${count.index}"
#  network_id = "${var.internal-ip-pool-id}"
#  admin_state_up = "true"
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[0]}"
#  }
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[1]}"
#  }
#}
#
resource "openstack_compute_instance_v2" "master" {
  count = "${var.master-count}"
  name  = "k8s-${var.cluster-name}-master-${count.index}"

  image_id        = "${var.master-image-id}"
  flavor_id       = "${var.master-flavor-id}"
  key_pair        = "${var.key-pair}"
  security_groups = ["${var.master-sec-group}"]

  network {
    #port = "${element(openstack_networking_port_v2.master-ports.*.id, count.index)}"
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

resource "openstack_compute_floatingip_v2" "master-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.master-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "master-flip-asso" {
  count = "${var.master-floating-ips}"
  floating_ip = "${element(openstack_compute_floatingip_v2.master-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
}

### -> output
data "template_file" "master" {
  count    = "${var.master-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-master-${count.index}"
    #ip = "temp"
    #ip        = "${element(openstack_compute_instance_v2.master.*.access_ip_v4, count.index)}"
    ip        = "${element(openstack_compute_floatingip_v2.master-flip.*.address, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.master-ports.*.all_fixed_ips.0, count.index)}"
  }
}

data "template_file" "master_noflip" {
  count    = "${var.master-count - var.master-floating-ips}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-master-${count.index + var.master-floating-ips}"
    #ip = "temp"
    ip        = "${element(openstack_compute_instance_v2.master.*.access_ip_v4, count.index + var.master-floating-ips)}"
    #ip        = "${element(openstack_networking_port_v2.master-ports.*.all_fixed_ips.0, count.index)}"
  }
}


data "template_file" "master-port-update" {
  count    = "${var.master-count}"
  template = "${file("${path.module}/template-port_update_single")}"
  vars {
    #node_name = "k8s-${var.cluster-name}-master-minion-${count.index}"
    #ip = "temp"
    instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
    #port_id        = "${element(openstack_compute_instance_v2.master-minion.*.network.0.port, count.index)}"
    #ip        = "${element(openstack_compute_instance_v2.master-minion.*.access_ip_v4, count.index)}"
   # ip        = "${element(openstack_networking_port_v2.master-minion-ports.*.fixed_ip, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.master-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}

