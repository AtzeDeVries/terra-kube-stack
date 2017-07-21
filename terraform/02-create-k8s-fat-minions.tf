### fat-minion Nodes

variable "fat-minion-count" { default = 1}
variable "fat-minion-floating-ips" { default = 1 }
variable "fat-minion-flavor-id" {}
variable "fat-minion-sec-group" {}
variable "fat-minion-image-id" {}


#resource "openstack_networking_port_v2" "fat-minion-ports" {
#  count = "${var.fat-minion-count}"
#  name = "k8s-${var.cluster-name}-fat-minion-${count.index}"
#  network_id = "${var.internal-ip-pool-id}"
#  admin_state_up = "true"
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[0]}"
#  }
#  allowed_address_pairs {
#    ip_address = "${var.allowed_address_pairs[1]}"
#  }
#}

resource "openstack_compute_instance_v2" "fat-minion" {
  count = "${var.fat-minion-count}"
  name  = "k8s-${var.cluster-name}-fat-minion-${count.index}"

  image_id        = "${var.fat-minion-image-id}"
  flavor_id       = "${var.fat-minion-flavor-id}"
  key_pair        = "${var.key-pair}"
  security_groups = ["${var.fat-minion-sec-group}"]

  network {
    #port = "${element(openstack_networking_port_v2.fat-minion-ports.*.id, count.index)}"
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

resource "openstack_compute_floatingip_v2" "fat-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.fat-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "fat-minion-flip-asso" {
  count = "${var.fat-minion-floating-ips}"
  floating_ip = "${element(openstack_compute_floatingip_v2.fat-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.fat-minion.*.id,count.index)}"
}

### -> output
data "template_file" "fat-minion" {
  count    = "${var.fat-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"

  vars {
    node_name = "k8s-${var.cluster-name}-fat-minion-${count.index}"
    #ip = "temp"
    ip        = "${element(openstack_compute_instance_v2.fat-minion.*.access_ip_v4, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.fat-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}


data "template_file" "fat-port-update" {
  count    = "${var.fat-minion-count}"
  template = "${file("${path.module}/template-port_update_single")}"
  vars {
    #node_name = "k8s-${var.cluster-name}-fat-minion-${count.index}"
    #ip = "temp"
    instance_id = "${element(openstack_compute_instance_v2.fat-minion.*.id, count.index)}"
    subnet_0 = "${var.allowed_address_pairs_0}"
    subnet_1 = "${var.allowed_address_pairs_1}"
    #port_id        = "${element(openstack_compute_instance_v2.fat-minion.*.network.0.port, count.index)}"
    #ip        = "${element(openstack_compute_instance_v2.fat-minion.*.access_ip_v4, count.index)}"
   # ip        = "${element(openstack_networking_port_v2.fat-minion-ports.*.fixed_ip, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.fat-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}

