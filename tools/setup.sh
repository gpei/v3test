#!/bin/bash

#conf_hostname=
#conf_GA_image_source=
#conf_new_image_source=
#conf_xpass_registry_server=
conf_GA_version="v3.0.0.1"
ose_infra_images="openshift3/ose-docker-registry
openshift3/ose-haproxy-router
openshift3/ose-deployer
openshift3/ose-sti-builder
openshift3/ose-docker-builder
openshift3/ose-keepalived-ipfailover
openshift3/ose-pod"


function clean_exist_image(){
    for i in $(docker images|awk '{print $3}' |grep -v IMAGE); do
        docker rmi -f $i
    done
}

function set_docker_host(){

    hostnamectl set-hostname $hostname 
    cur_ip_addr="$(/sbin/ip addr show | awk '/inet .*global/ { split($2,a,"/"); print a[1]; }' | head -1)"
    echo "$cur_ip_addr $hostname" >> /etc/hosts

    sed -i '/^-A INPUT -m state --state RELATED,ESTABLISHED/a\-A INPUT -p tcp -m state --state NEW -m tcp --dport 5000 -j ACCEPT' /etc/sysconfig/iptables
    systemctl restart iptables
    systemctl start docker-registry

}

function pull_ose_infra_images() {
    for i in $ose_infra_images; do
        docker pull "$GA_image_source/$i"
    done
}



function push_GA_images(){
    for i in $ose_infra_images; do
        docker tag $GA_image_source/$i $registry_server/$i && docker push $registry_server/$i
    done
}


clean_exist_image
yum install docker-registry -y
hostname="${conf_hostname:-upgrade.registry.com}"
set_docker_host

GA_image_source="${conf_GA_image_source:-www.example.com}"
pull_ose_infra_images

registry_server=$hostname:5000
push_GA_images
