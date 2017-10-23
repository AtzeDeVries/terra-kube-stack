#!/bin/sh

kube_config_dir=$HOME/.kube
timestamp=$(date '+%Y.%m.%d-%H.%M.%S')
echo making backup of current kube config
cp $kube_config_dir/config $kube_config_dir/config.$timestamp


mkdir -p $kube_config_dir/$2
hostname=$(ssh ubuntu@$1 hostname)
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/admin-$(hostname).pem' > $kube_config_dir/$2/admin-$hostname.pem
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/admin-$(hostname)-key.pem' > $kube_config_dir/$2/admin-$hostname-key.pem
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/ca.pem' > $kube_config_dir/$2/ca.pem


kubectl config set-cluster $2 --server=https://$1:6443 \
     --insecure-skip-tls-verify=true
#    --certificate-authority=$(pwd)/$2/ca.pem 

kubectl config set-credentials $2-admin \
    --certificate-authority=$kube_config_dir/$2/ca.pem \
    --client-key=$kube_config_dir/$2/admin-$hostname-key.pem \
    --client-certificate=$kube_config_dir/$2/admin-$hostname.pem 

#kubectl config set-credentials default-admin \
#    --certificate-authority=/path/to/ca.pem \
#    --client-key=/path/to/admin-key.pem \
#    --client-certificate=/path/to/admin.pem

kubectl config set-context $2-default --cluster=$2 --user=$2-admin --namespace=default
kubectl config use-context $2-default
