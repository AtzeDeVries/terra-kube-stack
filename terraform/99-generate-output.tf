
data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/template-inventory")}"

  vars {
    master_hosts   = "${join("\n",data.template_file.master.*.rendered)}"
    master_noflip_hosts   = "${join("\n",data.template_file.master_noflip.*.rendered)}"
    bastion_hosts   = "k8s-${var.cluster-name}-master-0 ansible_host=${openstack_networking_floatingip_v2.master-flip.0.address}"
    fat_hosts = "${join("\n",data.template_file.fat-minion.*.rendered)}"
    slim_hosts     = "${join("\n",data.template_file.slim-minion.*.rendered)}"
    ceph_hosts     = "${join("\n",data.template_file.ceph-minion.*.rendered)}"
  }
}

data "template_file" "ansible_sshconfig" {
  template = "${file("${path.module}/template-sshconfig")}"
  vars {
    bastion_hosts   = "${openstack_networking_floatingip_v2.master-flip.0.address}"
    sshuser       = "${var.ssh_user}"
  }
}

#data "template_file" "port-update" {
#  template = "${file("${path.module}/template-port_update")}"
#  vars { 
#    slim-ports = "${join("\n",data.template_file.slim-port-update.*.rendered)}"
#    master-ports = "${join("\n",data.template_file.master-port-update.*.rendered)}"
#    fat-ports = "${join("\n",data.template_file.fat-port-update.*.rendered)}"
#    ceph-ports = "${join("\n",data.template_file.ceph-port-update.*.rendered)}"
#  }
#}

output "ansible_inventory" {
  value = "${data.template_file.ansible_inventory.rendered}"
}

output "ansible_sshconfig" {
  value = "${data.template_file.ansible_sshconfig.rendered}"
}

#output "port-update" {
# value =  "${data.template_file.port-update.rendered}"
#}

#### -> output
#resource "template_file" "cronus" {
#  count    = "${var.cronus-count}"
#  template = "$${node_name} ansible_host=$${ip}"
#
#  vars {
#    node_name = "${var.cluster-name}-kube-cronus-${count.index}"
#    ip        = "${element(openstack_compute_floatingip_v2.cronus-flip.*.address, count.index)}"
#  }
#}
#
#resource "template_file" "peseidon" {
#  count    = "${var.peseidon-count}"
#  template = "$${node_name} ansible_host=$${ip}"
#
#  vars {
#    node_name = "${var.cluster-name}-kube-peseidon-${count.index}"
#    ip        = "${element(openstack_compute_floatingip_v2.peseidon-flip.*.address, count.index)}"
#  }
#}
#
#resource "template_file" "ponos" {
#  count    = "${var.ponos-count}"
#  template = "$${node_name} ansible_host=$${ip}"
#
#  vars {
#    node_name = "${var.cluster-name}-kube-ponos-${count.index}"
#    ip        = "${element(openstack_compute_floatingip_v2.ponos-flip.*.address, count.index)}"
#  }
#}
#
#
#resource "template_file" "hades" {
#  count    = "${var.hades-count}"
#  template = "$${node_name} ansible_host=$${ip}"
#
#  vars {
#    node_name = "${var.cluster-name}-kube-hades-${count.index}"
#    ip        = "${element(openstack_compute_instance_v2.hades.*.access_ip_v4, count.index)}"
#    #ip        = "${openstack_compute_instance_v2.access_ip_v4.count.index}"
#  }
#}
#
#resource "template_file" "gluster" {
#  count    = "${var.gluster-count}"
#  template = "$${node_name} ansible_host=$${ip} disk_volume_device_1=$${block_name}"
#
#  vars {
#    node_name  = "${var.cluster-name}-kube-gluster-${count.index}"
#    ip         = "${element(openstack_compute_instance_v2.gluster.*.access_ip_v4, count.index)}"
#    #ip         = "${openstack_compute_instance_v2.access_ip_v4.count.index}"
#    block_name = "${var.gluster-volume-block-name}"
#  }
#}
#
#resource "template_file" "zeus" {
#  count      = "${var.zeus-count}"
#  template   = "$${node_name} ansible_host=$${ip}"
#  vars {
#    node_name = "${var.cluster-name}-kube-zeus-${count.index}"
#    #ip        = "${element(openstack_compute_instance_v2.zeus.*.network.0.fixed_ip_v4, count.index)}"
#    ip        = "${element(openstack_networking_port_v2.zeus-network-ports.*.all_fixed_ips.0, count.index)}"
#   # ip        = "${element(openstack_compute_instance_v2.zeus.*.access_ip_v4, count.index)}"
#    #ip        = "${openstack_compute_instance_v2.access_ip_v4.count.index}"
#  }
#}
#
#
