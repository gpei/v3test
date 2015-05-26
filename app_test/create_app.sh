#!/bin/bash
app_json_file="hello-pod.json"


clean_env()
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


generate_avg()
{
  for i in $(cat test_cal)
  do
    echo "The avg time of get $i app is: " >> test_result
    cat record/app$i | grep seconds | awk '{sum+=$1}END{print sum/NR}'  >> test_result
  done
}
#--------------------------------------------------------------------------------------------

pre_create()
{
for i in `seq 1 $num`
do
  osadm new-project project$i --admin=test$i
done
}

app_create()
{
  for i in `seq 1 $num`
  do
    su - test$i -c "osc create -f $app_json_file -n project$i"  &
    get_time &
  done

}

get_time()
{
  start=$(date +%s.%N)
  while true
  do
    str=$(osc get pod -n project$i|grep Running)
  
    if [ -z "$str" ]
    then
      usleep 1
    else
      end=$(date +%s.%N)
      time_process $start $end
      break
    fi

  done

}

time_process()
{
    start=$1
    end=$2

    start_s=$(echo $start | cut -d '.' -f 1)
    start_ns=$(echo $start | cut -d '.' -f 2)
    end_s=$(echo $end | cut -d '.' -f 1)
    end_ns=$(echo $end | cut -d '.' -f 2)

    time=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))
    echo "The cost time of $i app is:" >> record/app$num
    echo "$time ms"  >> record/app$num
}



[ -d ./record ] || mkdir ./record

for num in 11 21 ; do
  echo "**********Test Result***************">> record/app$num
  echo $num >> test_cal

  sleep 90

  pre_create

  app_create

  
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
