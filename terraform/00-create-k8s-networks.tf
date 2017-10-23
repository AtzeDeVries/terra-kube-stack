##Setup needed variables
#"${file("${path.module}/ansible_inventory.tpl")}"
#-> variables
# please set variable overwrites in 'terraform.tfvars' file
### -> global
variable "cluster-name" {
  default = "default"
}

variable "ssh_user" {
  default = "ubuntu"
}


variable "allowed_address_pairs_0" {}

variable "allowed_address_pairs_1" {}

variable "key-pair" {}

variable "user-data-file" {
  default = "bootstrap.sh"
}

variable "internal-ip-pool" {}
variable "internal-ip-pool-id" {}
variable "floating-ip-pool" {}
variable "openstack_router_id" {}
variable "secgroup_admin_cidr" {}
variable "secgroup_public_cidr" {}
variable "k8s_network_subnet_cidr" {}
variable "dns_1" { default = "8.8.8.8"}
variable "dns_2" { default = "8.8.4.4"}
#variable "fat-minion-floating-ips" { default = 1 }
#variable "slim-minion-floating-ips" { default = 0 }
#
#variable "slim-minion-count" { default = 1}
#variable "fat-minion-count" { default = 1}
##-> resources
### -> floating ips

resource "openstack_networking_network_v2" "k8s-network" {
  name           = "k8s-${var.cluster-name}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "k8s-network-subnet" {
  name       = "k8s-${var.cluster-name}-subnet"
  network_id = "${openstack_networking_network_v2.k8s-network.id}"
  cidr       = "${var.k8s_network_subnet_cidr}"
  ip_version = 4
  dns_nameservers = ["${var.dns_1}","${var.dns_2}"]
}

resource "openstack_networking_router_interface_v2" "router_k8s_interface" {
  router_id = "${var.openstack_router_id}"
  subnet_id = "${openstack_networking_subnet_v2.k8s-network-subnet.id}"
}

resource "openstack_compute_secgroup_v2" "k8s-secgroup-managed" {
  name        = "k8s-${var.cluster-name}-secgroup-man"
  description = "securitygroup to make k8s work and and to managed."
}

resource "openstack_networking_secgroup_rule_v2" "AnyAnyRule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
  security_group_id = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${var.secgroup_admin_cidr}"
  security_group_id = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
}

resource "openstack_networking_secgroup_rule_v2" "ssl_api_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "${var.secgroup_admin_cidr}"
  security_group_id = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_public_tcp_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32727
  remote_ip_prefix  = "${var.secgroup_public_cidr}"
  security_group_id = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_public_udp_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 30000
  port_range_max    = 32727
  remote_ip_prefix  = "${var.secgroup_public_cidr}"
  security_group_id = "${openstack_compute_secgroup_v2.k8s-secgroup-managed.id}"
}

resource "openstack_compute_secgroup_v2" "k8s-secgroup-services" {
  name        = "k8s-${var.cluster-name}-secgroup-services"
  description = "Add secgroups for your k8s services here"
}


