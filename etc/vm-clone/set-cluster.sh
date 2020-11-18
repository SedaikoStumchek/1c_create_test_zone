#!/bin/bash
BASES_LIST="bgu zgu"
NAME="Test cluster node #1"
SERVER_DB="1c-db1-test"
PG_PASSWORD=''
LIC_SERVER="1c-lic1"

CLUSTER_USER_PWD=""  #"--cluster-user= --cluster-pwd="


ID_CLUSTER=$(rac cluster list |  grep -P 'cluster .+:' | sed -r 's/^.+: //')

NAME_CLUSTER=$(rac cluster list |  grep -P 'name .+:' | sed -r 's/^.+: //')

if [ "\"$NAME\"" != "$NAME_CLUSTER" ]
then	
	rac cluster update --cluster=$ID_CLUSTER --name="${NAME}"
fi


for IB in $BASES_LIST
do

rac infobase summary list --cluster=$ID_CLUSTER  $CLUSTER_USER_PWD | grep -q -P "name.+: ${IB}$"
if [ $? -ne 0 ]
then
   CMD="rac infobase --cluster=$ID_CLUSTER $CLUSTER_USER_PWD \
				create --create-database \
				--name=$IB \
				--dbms=PostgreSQL \
				--db-server=$SERVER_DB \
				--db-name=$IB \
				--locale=ru \
				--db-user=postgres \
				--db-pwd=${PG_PASSWORD} "
				
	#Символ $ в пароле все портит. Пришлось выполнение передать Perl
	perl -e "system(\"$CMD\")"			
fi


done

rac server list --cluster=$ID_CLUSTER  $CLUSTER_USER_PWD | grep -q -P "agent-host.+: ${LIC_SERVER}$"
if [ $? -ne 0 ]
then
	rac server insert --cluster=$ID_CLUSTER  $CLUSTER_USER_PWD \
		--agent-host=${LIC_SERVER} \
		--agent-port='1540' \
		--port-range='1560:1591' \
		--name=${LIC_SERVER} \
		--using=normal 
fi
