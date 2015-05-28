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
    real_num=$(grep ms record/app$i |wc -l)
    echo "The avg time of get $i app(success app num $real_num) is: " >> test_result
    cat record/app$i | grep ms | awk '{sum+=$8}END{print sum/NR}'  >> test_result
  done
}
#--------------------------------------------------------------------------------------------

pre_create()
{
for i in `seq 1 $num`
do
  osadm new-project project$i --admin=test$i
  cp -f hello-pod.json /home/test$i/
  port=$((6000+$i ))
  sed -i 's/6061/'$port'/' /home/test$i/hello-pod.json
done
}

app_create()
{

  start=$(date +%s.%N)
  echo "The beginning time is $start" >>  record/app$num

  for i in `seq 1 $num`
  do
    su - test$i -c "osc create -f $app_json_file -n project$i"  &
  done
  
  sleep 1

  for i in `seq 1 $num`
  do
    get_time $i  &
  done

}

get_time()
{
  seq=$1

  while true
  do
    str=$( osc get pod -n project$seq |grep Running )
  
    if [ -z "$str" ]
    then
      usleep 100
    else
      end=$(date +%s.%N)
      echo "The complete time of $seq app is $end" >>  record/app$num
      break
    fi

  done

}

time_process()
{
  start=$(grep beginning record/app$num |awk '{print $5}')

  for i in `seq 1 $num`
  do
    str=$( grep "$i app" record/app$num |awk '{print $8}')
    
    if [ -z "$str" ]
    then
      echo "The $i app is not created successfully!" >>  record/app$num
    else
      end=$str

      start_s=$(echo $start | cut -d '.' -f 1)
      start_ns=$(echo $start | cut -d '.' -f 2)
      end_s=$(echo $end | cut -d '.' -f 1)
      end_ns=$(echo $end | cut -d '.' -f 2)

      time=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))
      echo "The cost time of $i app is $time ms" >> record/app$num
    fi

   sleep 1
   done
}



[ -d ./record ] || mkdir ./record

for num in 5 10 15 20; do
  clean_env
  echo "**********Test Result***************">> record/app$num
  echo $num >> test_cal

  pre_create
  echo "Begin to create apps"

  app_create

  
#  if [ $fail = "true" ]
#  then
#    echo "There's pod failed to get running, pls check !!!!!!!"
#    break
#  fi

  echo "Creating apps, pls wait...."

  sleep 300
  time_process
  sleep 60
done

generate_avg
echo "Check test_result file for the final test result"
