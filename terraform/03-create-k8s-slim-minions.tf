### slim-minion Nodes

variable "slim-minion-count" { default = 1}
variable "slim-minion-floating-ips" { default = 1 }
variable "slim-minion-flavor-id" {}
variable "slim-minion-sec-group" {}
variable "slim-minion-image-id" {}

#
#resource "openstack_networking_port_v2" "slim-minion-ports" {
#  count = "${var.slim-minion-count}"
#  name = "k8s-${var.cluster-name}-slim-minion-${count.index}"
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
resource "openstack_compute_instance_v2" "slim-minion" {
  count = "${var.slim-minion-count}"
  name  = "k8s-${var.cluster-name}-slim-minion-${count.index}"

  image_id        = "${var.slim-minion-image-id}"
  flavor_id       = "${var.slim-minion-flavor-id}"
  key_pair        = "${var.key-pair}"
  security_groups = ["${var.slim-minion-sec-group}"]

  network {
    #port = "${element(openstack_networking_port_v2.slim-minion-ports.*.id, count.index)}"
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

resource "openstack_compute_floatingip_v2" "slim-minion-flip" {
  pool  = "${var.floating-ip-pool}"
  count = "${var.slim-minion-floating-ips}"
}

resource "openstack_compute_floatingip_associate_v2" "slim-minion-flip-asso" {
  count = "${var.slim-minion-floating-ips}"
  floating_ip = "${element(openstack_compute_floatingip_v2.slim-minion-flip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.slim-minion.*.id,count.index)}"
}



## -> output
data "template_file" "slim-minion" {
  count    = "${var.slim-minion-count}"
  template = "$${node_name} ansible_host=$${ip}"
  vars {
    node_name = "k8s-${var.cluster-name}-slim-minion-${count.index}"
    #ip = "temp"
    ip        = "${element(openstack_compute_instance_v2.slim-minion.*.access_ip_v4, count.index)}"
   # ip        = "${element(openstack_networking_port_v2.slim-minion-ports.*.fixed_ip, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.slim-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}

data "template_file" "slim-port-update" {
  count    = "${var.slim-minion-count}"
  template = "${file("${path.module}/template-port_update_single")}"
  vars {
    #node_name = "k8s-${var.cluster-name}-slim-minion-${count.index}"
    #ip = "temp"
    instance_id = "${element(openstack_compute_instance_v2.slim-minion.*.id, count.index)}"
    subnet_0 = "${var.allowed_address_pairs_0}"
    subnet_1 = "${var.allowed_address_pairs_1}"
    #port_id        = "${element(openstack_compute_instance_v2.slim-minion.*.network.0.port, count.index)}"
    #ip        = "${element(openstack_compute_instance_v2.slim-minion.*.access_ip_v4, count.index)}"
   # ip        = "${element(openstack_networking_port_v2.slim-minion-ports.*.fixed_ip, count.index)}"
    #ip        = "${element(openstack_networking_port_v2.slim-minion-ports.*.all_fixed_ips.0, count.index)}"
  }
}

# neutron port-update 5662a4e0-e646-47f0-bf88-d80fbd2d99ef --allowed_address_pairs list=true type=dict ip_address=10.233.0.0/18
# neutron port-update 5662a4e0-e646-47f0-bf88-d80fbd2d99ef --allowed_address_pairs list=true type=dict ip_address=10.233.64.0/18

# a=$(neutron port-list -c id -c device_id | grep $ID | awk '{print $2}')
