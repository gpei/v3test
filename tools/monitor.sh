services="/usr/bin/openshift systemd-journal /usr/bin/docker"

service_monitor()
{
  while true
  do
    echo "*************************************************************" >> m_log
    date >> m_log
    for i in $services
    do
      ps aux|grep "$i" |grep -v grep >> m_log
    done
    echo "" >> m_log 
    sleep 1
   done
}


dstat  -cnmdlt >> n_log &
service_monitor 
