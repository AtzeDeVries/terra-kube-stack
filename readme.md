# Kubernetes deployment on Openstack

There are many ways to deploy kubernetes, this tutorial will describe a deployment from the beginning to the end. 
The configuration is pretty configurable and easy to extend.

### Requirements
* ansible 
* terraform
* openrc file for openstack
* securitygroup with allow all with same securitygroup and allow tcp 6443 to admin (kube api)
    * security group creation with terraform is planned. 
* openstack network with dhcp
* floating ip network
* ssh key (also registerd within openstack)
    * private key is asumed to be in `~/.ssh/id_rsa`
* Image of Ubuntu 16.04 with correct metadata
    * check https://wiki.openstack.org/wiki/Documentation/HypervisorTuningGuide#Image_Metadata
* nova-client on your machine
* neutron-client on your machine
* kubectl (kubernetes client)

### Steps to deploy

#### Clone some stuff
```shell
git clone https://github.com/AtzeDeVries/terra-kube-stack
cd terra-kube-stack
git clone https://github.com/kubernetes-incubator/kubespray
cp -fr kubespray/inventory ../
```
#### Set some settings
copy `tf-state/terraform.tfvars.template` to `tf-state/terraform.tfvars`
then edit `terraform.tfvars`. Make sure the subnets in `allowed_address_pairs` are unique in your network
```terraform
### -> global
cluster-name = "test"
key-pair = "atze"
internal-ip-pool = "net04"
internal-ip-pool-id = "cae5d471-7363-428e-8e08-5bb30c7dbaeb"
floating-ip-pool = "external"
allowed_address_pairs_0 = "10.237.0.0.18/24"
allowed_address_pairs_1 = "10.237.64.0/18"


### -> master
master-count = 1
master-floating-ips = 1
master-image-id = "45f40430-9c95-49a8-bce2-151d05aa9f5e"
master-flavor-id = "488e3446-c46b-4288-bbfe-d3530de92e99"
master-sec-group = "tight"

fat-minion-count = 2
fat-minion-floating-ips = 1
fat-minion-image-id = "45f40430-9c95-49a8-bce2-151d05aa9f5e"
fat-minion-flavor-id = "5c546141-7dcd-4fa5-bc3b-c703b5889e26"
fat-minion-sec-group = "tight"

slim-minion-count = 1
slim-minion-floating-ips = 0
slim-minion-image-id = "45f40430-9c95-49a8-bce2-151d05aa9f5e"
slim-minion-flavor-id = "488e3446-c46b-4288-bbfe-d3530de92e99"
slim-minion-sec-group = "tight"

ceph-minion-count = 3
ceph-minion-floating-ips = 0
ceph-minion-image-id = "df3c858f-7d26-4e97-ba89-6abf49e6b076"
ceph-minion-flavor-id = "67840113-ea9a-4d62-8c4c-55564d3ebad4"
ceph-minion-sec-group = "tight"
```
The options are quite explainary.


Then edit `inventory/group_vars/all.yml` and add `cloud_provider: openstack`

Then edit `inventory/group_vars/k8s-cluster.yml` and set
```yaml
bootstrap_os: ubuntu
```
The default networking is set to `calico`. You can change this to `flannel`. For flannel
there are no special network requirements. For calico you need to run the `port-update.sh` script (chech later in 
documentation). For calcio you can set the `ipip` mode. For the best performance (native performance) you need to 
set `ipip: false`, but this will not work in all setups. You need to make use the 'allowed adress pairs' you set are 
unused in your network, also your network might not allow it. Having `ipip: true` (which is default) will allow you 
to use `calico` in most situations, but the performance is less, but still good. 
You can change `dns` to
```yaml
dns_mode: kubedns
```
Then change also `kube_version`  to `kube_version: v1.6.2` (or an other version). And 
very import, change the `kube_api_pwd`. If you want to add some overwrites you can also
add them here. For example i made a patch on the hyberkube docker images (add our certificate), so
i've added
```yaml
hyperkube_image_repo: "atzedevries/hyperkube"
```
#### Boostrap of your instances
copy `./scrips/bootstrap.sh.template ./terraform/bootstrap.sh
You can edit `terraform/boostrap.sh` to add some stuff to the servers. I've added some stuff
to make cinder volumes work, install python etc. I've also added our Openstack certificate, since it is
not accepted by ubuntu by default. Your install of kubernetes will fail if the cerifitcate is not accepted.

#### Create instances

Now run
```shell
source <path to your rc file>
terraform apply -parallelism=1 -state=./tf-state/terraform.tfstate -var-file=./tf-state/terraform.tfvars ./terraform
```
What for a few minutes for terraform to be completed and the instances to be up and running

We can use the output of terraform the setup some settings for ansible.
```shell
terraform output -state=./tf-state/terraform.tfstate  ansible_inventory > inventory/inventory
terraform output -state=./tf-state/terraform.tfstate  ansible_sshconfig > ./ssh-bastion.conf
```
And if you are using `calico`
```shell
terraform output -state=./tf-state/terraform.tfstate  port-update > tf-state/port-update.sh
```

Now patch the openstack ports
```shell
sh tf-state/port-update.sh
```


#### Install kubernetes

After this you can check if your nodes are op and running 
```shell
ansible all  -i inventory/inventory -u ubuntu -m ping
```
This should give a succes.

Now we can install kubernetes, so we run the playbook

```shell
ansible-playbook -i inventory/inventory \
    -u ubuntu -b \
    -e kube_service_adresses=<your first subnet from allowed address pairs> \
    -e kube_pods_subnet=<your second subnet from allowed address pairs> \
    kubespray/cluster.yml
```
Now wait about 5 to 10 minutes. (rerun if it fails, it might finish then)


#### Get access
Run 
```shell
scripts/get-certs.sh <floating ip of master/bastion> <name of cluster>
```
This will download the certificates of your kubernetes cluster and configure kubectl. 


You can check the cluster now

```shell
kubectl get nodes -o wide
kubectl get cs
kubectl get all --all-namespaces
```

#### Set cinder storage class
If you want to use cinder for persistant volumes (you can use more persistant volume types) you
can create a cinder storage class. Check `kube-resources/cinder-storageclass.yaml` to check if the 
settinings are correct. 
If you want to create this storage class run
```shell
kubectl create -f kube-resources/cinder-storageclass.yaml
kubectl get pv
```

### Adding or removing nodes

#### Add
It is very easy to add or remove nodes in your cluster. First update your `terraform.tfvars` with the new
amount of nodes and then run all the steps again which are under [Create instances](#create-instances)

After the new nodes have been created, run the steps in [Install kubernetes](#install-kubernetes). That's it!

#### Remove
You should first remove the containers (if you want to keep them) from your to be removed node. You can use the
`kubectl drain` command for that. After this, you can modify `terraform.tfvars` and run the the commands in 
[Create instances](#create-instances)







