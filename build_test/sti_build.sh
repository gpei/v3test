#!/bin/bash

image_source="openshift/ruby-20-rhel7~https://github.com/gpei/ruby-hello-world.git"
build_config="ruby-hello-world"
fail="false"

date_process()
{
  for i in `seq 1 $num`
  do
    str1=$(osc build-logs -n project$i $build_config-1 | sed -n '$p' |grep "Successfully pushed")

    #check whether the sti build is success, if failed, pass the time process part
    if [ -z "$str1" ]
    then
      echo "The $i sti build failed!!" >> record/build$num
      fail="true"
    else
      
      #get the start time and end time of sti build from build log of each build
      time1=$(osc build-logs -n project$i $build_config-1 | sed -n '1p' |awk '{print $1}')   
      time1=$(date +%s -d $time1)
    
      time2=$(osc build-logs -n project$i $build_config-1 | sed -n '$p' |awk '{print $1}')
      time2=$(date +%s -d $time2)
  
      b_time=$(($time2-$time1))

      echo "$i sti build cost:"  >> record/build$num
      echo "$b_time seconds"  >> record/build$num
       
      #check whether the deployment is success
      pod=$(osc get pod -n project$i |grep $build_config| grep -v sti-build|awk '{print $1}')
      str2=$(osc log $pod -n project$i |sed -n '$p'|grep start)
  
      if [ -z "$str2" ]
      then
        echo "The $i deployment failed!!" >> record/build$num
        fail="true"
      else

        time3=$(osc log $pod -n project$i |sed -n '$p'|awk '{print $1}')
        time3=$(date +%s -d $time3)
        
        d_time=$(($time3-$time2))

        echo "$i deployment cost:"  >> record/build$num 
        echo "$d_time sdnoces"  >> record/build$num
      fi
    fi

  done
}

generate_avg()
{
  for i in $(cat test_cal)
  do
    success_num1=$(cat record/build$i | grep seconds | wc -l)
    echo "There's $success_num1 sti build succeed during $i build testing, the avg time of the $success_num1 build is: " >> test_result
    cat record/build$i | grep seconds | awk '{sum+=$1}END{print sum/NR}'  >> test_result
    
    success_num2=$(cat record/build$i | grep sdnoces | wc -l)
    echo "There's $success_num2 deployment succeed during $i build testing, the avg time of the $success_num2 deployment is: " >> test_result
    cat record/build$i | grep sdnoces | awk '{sum+=$1}END{print sum/NR}'  >> test_result
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

      if [ -z "$str3" ]
      then
        fail="false"
      else
        fail="true"
      fi

      if [ -z "$str2" ]
      then
        flag="true"
      else
        flag="false"
        break
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

pod_check()
{
  while true
  do
    r_pod=0

    for i in `seq 1 $num`
    do
      status=$( osc get pod -n project$i|grep $build_config |grep -v sti-build |grep -v ose-deployer|awk '{print $7}')


      if [ $status = "Running" ]
      then
        let r_pod+=1
      elif [ $status = "Failed" ]
      then
        fail="true"
        let r_pod+=1
      fi
 
    done
    
    if [ $r_pod -eq $num ]
    then
      echo "All $num pod are finished now!"
      break
    else
      echo "Some pods still not get running..."
      sleep 5
    fi

  done
}


#generate is for openshift project
#osc create -f image-streams.json -n openshift

[ -d ./record ] || mkdir ./record

for num in 3 ; do
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
  pod_check

  date_process
  #once building finished, do the following steps

  if [ $fail = "true" ]
  then
    echo "There's build failed, pls check!!"
    break
  else
    clean_projects
    clean_images
  fi
 
  sleep 300
done

generate_avg
echo "Check test_result file for the final test result"
