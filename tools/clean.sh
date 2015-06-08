node1=minion1.cluster.local
node2=minion2.cluster.local

ssh root@$node1 ./clean_env.sh
ssh root@$node2 ./clean_env.sh
