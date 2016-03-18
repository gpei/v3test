clean_container()
{


list=$(docker ps -a |grep Exited |awk '{print $1}')
for i in $list; do docker rm -v -f $i ; done

}


clean_images()
{
    list=$(docker images|grep project|awk '{print $3}')
    for id in $list
    do
      docker rmi -f $id
    done

  echo "All images cleaned up!!!"
}


clean_images
clean_container

