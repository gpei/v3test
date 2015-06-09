node1=minion1.cluster.local
node2=minion2.cluster.local

scp env_clean.sh minion1.cluster.local:/root/
scp env_clean.sh minion2.cluster.local:/root/

ssh root@$node1 ./env_clean.sh
ssh root@$node2 ./env_clean.sh
