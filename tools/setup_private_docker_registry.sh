#!/bin/bash

#conf_hostname=
images="xxx"


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

function pull_images() {
    for i in $images; do
        docker pull "$image_source/$i"
    done
}



function push_images(){
    for i in $images; do
        docker tag $image_source/$i $registry_server/$i && docker push $registry_server/$i
    done
}


clean_exist_image
yum install docker-registry -y
hostname="${conf_hostname:-upgrade.registry.com}"
set_docker_host

image_source="${conf_image_source:-www.example.com}"
pull_images

registry_server=$hostname:5000
push_images
