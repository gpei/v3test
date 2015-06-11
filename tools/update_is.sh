

for i in `seq 1 15`
do 
  osc update is ruby-20-centos7 --patch='{"apiVersion": "v1beta3", "metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"} }}' -n project$i
done
