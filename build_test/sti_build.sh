#!/bin/bash

image_source="openshift/ruby-20-rhel7~https://github.com/gpei/ruby-hello-world.git"
build_config="ruby-hello-world"
fail="false"

date_process()
{
  for i in `seq 1 $num`
  do
    str1=$(osc build-logs -n project$i $build_config-1 | sed -n '$p' |grep "Successfully pushed")

    if [ -z "$str1" ]
    then
      echo "The $i sti build failed!!" >> record/build$num
    else
      time1=$(osc build-logs -n project$i ruby-hello-world-1 | sed -n '1p' |awk '{print $1}')   
      time1=$(date +%s -d $time1)
    
      time2=$(osc build-logs -n project$i ruby-hello-world-1 | sed -n '$p' |awk '{print $1}')
      time2=$(date +%s -d $time2)
  
      time=$(($time2-$time1))

      echo "$i sti build cost:"  >> record/build$num
      echo "$time seconds"  >> record/build$num
    fi

  done
}

generate_avg()
{
  for i in $(cat test_cal)
  do
    success_num=$(cat record/build$i | grep seconds | wc -l)
    echo "There's $success_num sti build succeed during $i build testing, the avg time of the $success_num build is: " >> test_result
    cat record/build$i | grep seconds | awk '{sum+=$1}END{print sum/NR}'  >> test_result
  done
}

clean_projects()
{
  for i in `seq 1 $num`
  do
    osc delete project project$i
  done

  while true
  do
    sleep 10
    str1=$( osc get project |grep Terminating)

    if [ -z "$str1" ]
    then
      break
    else
      echo "Still Terminating..."
    fi

  done

  echo "All projects cleaned up!!!"
}

clean_images()
{
  for i in `seq 1 $num`
  do
    list=$(docker images|grep project$i|awk '{print $2}')
    for id in $list
    do
      docker rmi -f $id
    done
  done
  
  echo "All images cleaned up!!!"
}

create_app()
{

for i in `seq 1 $num`
do
  osadm new-project project$i --admin=test$i
  su - test$i -c "osc new-app $image_source  -n project$i"
done

echo "$num $build_config app created."

}

trigger_build()
{
  for i in `seq 1 $num`
  do
    su - test$i -c "osc start-build $build_config -n project$i"  &
  done
}

building_check()
{
  while true
  do

    for i in `seq 1 $num`
    do
      str2=$( osc get build -n project$i |grep -e Running -e Pending)
      str3=$( osc get build -n project$i |grep Failed)

      if [ -z "$str2" ]
      then
        flag="true"
      else
        flag="false"
        break
      fi

      if [ -z "$str3" ]
      then
        fail="false"
      else
        fail="true"
      fi

    done

    if [ $flag = "true" ]
    then
      echo "All building finished."
      break
    else
      echo "Still have building running..."
      sleep 10
    fi

  done
}


#generate is for openshift project
#osc create -f image-streams.json -n openshift

[ -d ./record ] || mkdir ./record

for num in 3 8 ; do
  echo "**********Test Result***************">> record/build$num
  echo $num >> test_cal
  echo "Creating $num app"

  create_app

  echo "waiting for trigger build..."
  sleep 60

  trigger_build
  sleep 300

  #wait for the building finished
  building_check 
  sleep 60
 


  #once building finished, do the following steps
    if [ $fail = "true" ]
    then
      echo "There's build failed, pls check!!"
      break
    else
      clean_projects
      clean_images
    fi
 
  date_process
  sleep 300
done

generate_avg
echo "Check test_result file for the final test result"

