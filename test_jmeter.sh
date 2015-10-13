#!/bin/bash

run_jmeter()
{
  #Run jmeter with test profile test.jmx which defined the LoopController.loops & HTTPSampler.domain
#  ../jmeter -n -t test.jmx
  /root/apache-jmeter-2.9/bin/jmeter -n -t test.jmx
  sleep 60
}


get_data()
{
  #process data in tmp file
  awk -F "," '{print $2}' jmeter.jtl > data_tmp

  #Average/Min/Max response time of all requests
  Average=$(cat data_tmp | awk '{sum+=$1}END{print sum/NR}')

  Min=$(cat data_tmp |sort -nr | sed -n '1p')

  Max=$(cat data_tmp |sort -nr | sed -n '$p')

  #Medium Line and 90% Line of all requests
  N50=$number*0.5
  N90=$number*0.9
  Medium=$(cat data_tmp|sort -n| awk "NR==$N50" )
  Line90=$(cat data_tmp|sort -n| awk "NR==$N90" )

  echo "AVG=$Average , Min=$Min , Max=$Max , Medium=$Medium , 90%Line=$Line90" |tee -a record/$appname-$number-result


}

is_all_pass()
{
  #check whether Error happen
  Success_number=$(grep OK jmeter.jtl |wc -l)
  if [ $Success_number -eq $number ]
    then
      echo "All success!" |tee -a record/$appname-$number-result
    else
      echo "Error happened..." |tee -a record/$appname-$number-result
  fi
}

copy_log()
{
  cp jmeter.jtl record/$appname-$number-jmeter.jtl
  #recover test.jmx and logs
  > jmeter.jtl
}


[ -d ./record ] || mkdir ./record


for i in 1 
do
  sed -i /LoopController.loops/s/1/$i/ test.jmx
  run_jmeter
 
  number=$(cat jmeter.jtl |wc -l)
  appname=$(grep "com.cn" test.jmx |cut -c 49-55)

  get_data
  is_all_pass
  copy_log

  sed -i /LoopController.loops/s/$i/1/ test.jmx
#  sleep 300
done
