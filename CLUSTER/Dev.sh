#!/bin/bash

sudo mkdir -p /etc/vbox/
echo "* 0.0.0.0/0 ::/0" | sudo tee -a /etc/vbox/networks.conf

cd /home/devops/Dev/CLUSTER
vagrant up
cd /home/devops/Dev/CLUSTER
cd configs
export KUBECONFIG=$(pwd)/config
vagrant ssh -c "/vagrant/scripts/dashboard.sh" controlplane
#make dashboard accessible
#kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}"  
#kubectl proxy
#http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
#to shutdown
#vagrant halt
#to restart
#vagrant up
#to destroy
#vagrant destroy -f

