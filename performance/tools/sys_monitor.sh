#!/bin/bash
#which dstat > /dev/null
#[ $? -ne 0 ] && yum install dstat -y
while true
do

  dstat -cnmdlt 1 1
  echo
  echo "****** Cpu consume top 5: ******"
  ps auxw|head -1;ps auxw|sort -rn -k3|head -5
  echo
  echo "****** Mem consume top 5: ******"
  echo
  ps auxw|head -1;ps auxw|sort -rn -k4|head -5

  echo
  echo "***** System process status record *****"
  ps auxw|egrep '/usr/bin/openshift | /usr/bin/docker'|grep -v grep
  echo

done
