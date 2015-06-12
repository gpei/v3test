#!/bin/bash

master_hostname=`hostname`
start_num=11
end_num=20

add_user()
{
for i in `seq ${start_num} ${end_num}`
do
 useradd test$i
 htpasswd -b /etc/openshift/htpasswd test$i redhat
done
}

initialize_user()
{
for i in `seq ${start_num} ${end_num}`
do
  su - test$i -c "rm -f ~/.config/openshift/.config"
  su - test$i -c "oc login -u test$i -p redhat --certificate-authority=/etc/openshift/master/ca.crt --server=https://${master_hostname}:8443"
done
}

allocate_project()
{
for i in `seq ${start_num} ${end_num}`
do
  osadm new-project project$i --admin=test$i
done
}

add_user
initialize_user
#allocate_project
