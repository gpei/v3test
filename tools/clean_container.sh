list=$(docker ps -a |grep Exited |awk '{print $1}')
for i in $list; do docker rm -f $i ; done
