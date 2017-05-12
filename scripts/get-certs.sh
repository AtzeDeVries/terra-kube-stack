#!/bin/sh

mkdir -p $2
hostname=$(ssh ubuntu@$1 hostname)
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/admin-$(hostname).pem' > $2/admin-$hostname.pem
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/admin-$(hostname)-key.pem' > $2/admin-$hostname-key.pem
ssh ubuntu@$1 'sudo cat /etc/kubernetes/ssl/ca.pem' > $2/ca.pem


kubectl config set-cluster $2 --server=https://$1:6443 \
     --insecure-skip-tls-verify=true
#    --certificate-authority=$(pwd)/$2/ca.pem 

kubectl config set-credentials default-admin \
    --certificate-authority=$(pwd)/$2/ca.pem \
    --client-key=$(pwd)/$2/admin-$hostname-key.pem \
    --client-certificate=$(pwd)/$2/admin-$hostname.pem 

#kubectl config set-credentials default-admin \
#    --certificate-authority=/path/to/ca.pem \
#    --client-key=/path/to/admin-key.pem \
#    --client-certificate=/path/to/admin.pem

kubectl config set-context $2-default --cluster=$2 --user=default-admin --namespace=default
kubectl config use-context $2-default
