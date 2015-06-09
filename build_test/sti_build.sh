#!/bin/bash

template="ruby-helloworld-sample"
tem_file="application-template-stibuild.json"
build_config="ruby-sample-build"
frontend_name="frontend"
rc_name="frontend-1"
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
      time1=$(osc build-logs -n project$i $build_config-1 | sed -n '1p' |awk '{print $2}')   
      time1=$(date +%s -d $time1)
    
      time2=$(osc build-logs -n project$i $build_config-1 | sed -n '$p' |awk '{print $2}')
      timeb=$time2
      time2=$(date +%s -d $time2)
  
      b_time=$(($time2-$time1))

      echo "$i sti build cost:"  >> record/build$num
      echo "$b_time seconds"  >> record/build$num
       
      #check whether the deployment is success
      pod=$(osc get pod -n project$i |grep $frontend_name |grep -v hook |awk '{print $1}')
      str2=$(osc logs $pod -n project$i |sed -n '$p'|grep start)
  
      if [ -z "$str2" ]
      then
        echo "The $i deployment failed!!" >> record/build$num
        fail="true"
      else

        time3=$(osc logs $pod -n project$i |sed -n '$p'|awk '{print $1,$2}' |cut -c 2-20)
        
        #time4 is timeb transfer to CST(the time zone of host), time5 is time3 transfer to CST
        time4=$( date +%s -d "$timeb EDT")
        time5=$( date +%s -d "$time3 GMT")
         
        d_time=$(($time5-$time4))
        
        echo "The finished time of $i project deploy is $time3" >> record/build$num
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


pre_create()
{

for i in `seq 1 $num`
do
  osadm new-project project$i --admin=test$i
  cp -f $tem_file /home/test$i/

  su - test$i -c "osc create -f $tem_file -n project$i"

done

echo "$num $build_config app created."

}

app_create()
{
  for i in `seq 1 $num`
  do
    su - test$i -c "osc new-app --template=$template -n project$i" &
  done
}

building_check()
{
  while true
  do
    r_build=0

    for i in `seq 1 $num`
    do
      status=$( osc get build -n project$i|grep Source |awk '{print $3}')

      if [ $status = "Complete" ]
      then
        let r_build+=1
      elif [ $status = "Failed" ]
      then
        fail="true" 
        let r_build+=1
      fi 
    
     done


    if [ $r_build -eq $num ]
    then
      echo "All $num build are finished now!"
      break
    else
      echo "some build still not finished..."
      sleep 5
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
      status=$( osc get pod -n project$i|grep $frontend_name |grep -v hook|awk '{print $5}')
      noready=$( osc get pod -n project$i |grep "not ready" )

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


#generate is for openshift project
#osc create -f image-streams.json -n openshift

[ -d ./record ] || mkdir ./record

for num in 5 ; do
  echo "**********Test Result***************">> record/build$num
  echo $num >> test_cal

  pre_create

  echo "waiting for create apps..."
  sleep 10

  app_create
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
  fi
 
#  sleep 300
done

generate_avg
echo "Check test_result file for the final test result"
