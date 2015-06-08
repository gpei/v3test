#!/bin/bash

template="ruby-helloworld-sample"
tem_file="application-template-stibuild.json"
#bxuild_config="ruby-sample-build"
frontend_name="frontend-1"
rc_name="frontend-1"
fail="false"


scale_app()
{
  
  # for beta4, we could use osc resize/scale cmd
   osc resize --replicas=$num replicationcontrollers $rc_name -n project1

#  osc get rc -o json -n project1 > rc.json
#  sed -i '0,/\"replicas\"\:\ 1/s//\"replicas\"\:\ '$num'/' rc.json
#  osc update -f rc.json -n project1
}

build_check()
{
  while true
  do
    
    str1=$( osc get build -n project1 |grep Complete)
    
    if [ -z "$str1" ]
    then
      echo "still in building, pls wait..."
      sleep 30
    else
      break
    fi
  done

}


pod_check()
{
  while true
  do

    r_pod=$(osc get pod -n project1 |grep $frontend_name |grep -v hook|grep Running|wc -l )
    str=$(osc get pod -n project1 |grep $frontend_name |grep -v hook| grep -i Failed)
    noready=$(osc get pod -n project1 |grep "not ready")

    if [ -z "$str" ]
    then
      fail="false"
    else
      fail="true"
    fi

    if [ $r_pod -eq $num ]
    then
      if [ -z "$noready" ]
      then
         echo "All $num pod are running now!"
         break
      else
         echo "some pod still not ready..."
         sleep 5
      fi 
    else
      echo "Some pods still not get running..."
      sleep 5
    fi
    
  done
}


date_process()
{
    pod_list=$(osc get pod -n project1 |grep $frontend_name |grep -v hook|grep -v $origin_pod| awk '{print $1}')

    for i in $pod_list
    do  
      time=$(osc logs $i -n project1 |sed -n '$p'|awk '{print $1,$2}' |cut -c 2-20)
      e_time=$(date +%s -d $time)
  
      cost_time=$(($e_time-$s_time))
  
      echo "The cost time of pod $i is:" >> record/rc$num
      echo "$cost_time seconds" >> record/rc$num
    done
}


clean_env()
{
  osc delete project project1
  
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

#  image=$( docker images|grep project1 |awk '{print $2}' )
#  docker rmi -f $image

}


generate_avg()
{
  for i in $(cat test_cal)
  do
    r=$(( $i - 1 ))
    echo "The avg time of get $r more pod is: " >> test_result
    cat record/rc$i | grep seconds | awk '{sum+=$1}END{print sum/NR}'  >> test_result
  done
}



[ -d ./record ] || mkdir ./record

for num in 11 21 31; do
  echo "**********Test Result***************">> record/rc$num
  echo $num >> test_cal

  osadm new-project project1 --admin=test1
  cp -f $tem_file /home/test$i/
  su - test1 -c "osc create -f $tem_file -n project1"
  su - test1 -c "osc new-app --template=$template -n project1"
#  su - test1 -c "osc start-build $build_config -n project1"
  sleep 300
  build_check 

  origin_pod=$(osc get pod -n project1 |grep $frontend_name |grep -v hook |awk '{print $1}')

  echo "Ready to scale the app to $num pod"

  scale_app
  s_time=`date +%s`

  pod_check

  date_process
  
  if [ $fail = "true" ]
  then
    echo "There's pod failed to get running, pls check !!!!!!!"
    break
  fi

  clean_env
  sleep 300
done

generate_avg
echo "Check test_result file for the final test result"
