old_version=
new_version=

hosts=""
#replace image_version
for i in $hosts
do
  ssh $i "sed -i 's/$old_version/$new_version/g' /etc/sysconfig/atomic-openshift-node /etc/sysconfig/openvswitch "
  ssh $i "systemctl restart docker"
done
 
sed -i 's/$old_version/$new_version/g' /etc/sysconfig/atomic-openshift-master
systemctl restart atomic-openshift-master


#replace the oc/oadm command
sed -i 's/$old_version/$new_version/g' /usr/local/bin/oc /usr/local/bin/oadm

#update docker-registry
oc get dc docker-registry -o yaml > registry.yaml
sed -i 's/$old_version/$new_version/g' registry.yaml
cat registry.yaml | oc replace -f -

#update router 
oc get dc router -o yaml > router.yaml
sed -i 's/$old_version/$new_version/g' router.yaml
cat router.yaml | oc replace -f -

