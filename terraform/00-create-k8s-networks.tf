##Setup needed variables

# The following roles are in the cluster:
# * cronus   ( master, etcd, kubelet, bastion, floating_ip ) (# == 1)
# * peseidon ( master, etcd, kubelet, floating_ip ) ( 0 =< # =< 2)
# * zues     ( master, etcd, kubelet ) (0 =< # =< 2)
# * ponos    ( kubelet, floating_ip ) ( # >= 0 )
# * hades    ( master, etcd ) ( 0 =< # =< 2) 

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

variable "allowed_address_pairs" {
  default = ["10.233.0.0/18","10.233.64.0/18"]
}

variable "key-pair" {}

variable "user-data-file" {
  default = "bootstrap.sh"
}

variable "internal-ip-pool" {}
variable "internal-ip-pool-id" {}
variable "floating-ip-pool" {}

#variable "fat-minion-floating-ips" { default = 1 }
#variable "slim-minion-floating-ips" { default = 0 }
#
#variable "slim-minion-count" { default = 1}
#variable "fat-minion-count" { default = 1}
##-> resources
### -> floating ips



