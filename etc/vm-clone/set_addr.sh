#!/bin/bash

#Файл настроек
MAC_LIST=/etc/vm-clone/mac_list.txt

if [ ! -f $MAC_LIS ]
then
	echo "File $MAC_LIS not found!"
	exit 0
fi

#Имя интерфейса
DEV=$(ip a show scope link | head -n1 | cut -d':' -f2 | xargs)

#Конфигурационный файл настройки сети
IF_CONF=/etc/sysconfig/network-scripts/ifcfg-$DEV

#Текущий MAC адрес 
CUR_MAC=$(ip a show $DEV | head -n2 | tail -n1 | awk '{print $2}')

if [[ -z "$CUR_MAC" ]] ; then
	echo "Can't determine MAC address" >&2
	exit 1
fi

#Текущий IPv4
CUR_IP=$(cat $IF_CONF | grep 'IPADDR=' | cut -d'"' -f2)

#Текущее имя хоста
CUR_HOST=$(hostname)

#Если MAC есть в файле, то это продакшин
if grep -q "$CUR_MAC" $MAC_LIST
then
	TYPE=$(grep $CUR_MAC $MAC_LIST | xargs | cut -d' ' -f1)
	echo "This is prodaction server type '$TYPE'"
    exit 0
fi

TYPE=$(grep $CUR_IP $MAC_LIST | xargs | cut -d' ' -f1)
MAC_F=$(grep $CUR_IP $MAC_LIST | xargs | cut -d' ' -f2)

#Если тестовый узел уже настроен, то ничего делать не надо
if [ $MAC_F == "clone" ]
then
	echo "This is clonning server type '$TYPE'"
    exit 0
fi

IP=$(grep -E "$TYPE .* clone " $MAC_LIST | xargs | cut -d' ' -f3)
HOST=$(grep -E "$TYPE .* clone " $MAC_LIST | xargs | cut -d' ' -f4)


echo "$DEV $CUR_MAC $CUR_IP $CUR_HOST"


if [ $IP != $CUR_IP ]
then
    sed -i -r "s/^IPADDR=.+/IPADDR=\"${IP}\"/" $IF_CONF
    echo "setting IP=$IP"
fi

if [ $HOST != $CUR_HOST ]
then
    hostnamectl set-hostname $HOST   
    echo "setting HOST=$HOST"
    sed -r "s/^Hostname=.+/Hostname=${HOST}/"  -i /etc/zabbix/zabbix_agentd.conf
fi

if [ $TYPE == "app-cs" ]
then
    rm -rf /home/usr1cv8/.1cv8
    echo "Remove cluster 1C"	
    rm -rf /var/1C/license/*.*
    echo "Remove licenses 1C"    
    sed -r 's/.+SRV1CV8_DEBUG=/SRV1CV8_DEBUG=1/' -i /etc/sysconfig/srv1cv83
    echo "Debug  mode 1C enabled."
fi

if [ $TYPE == "db-srv" ]
then
	PGDATA=/mnt/db_disk/pg_data
	
	APP_IP=$(grep -E "app-cs .* clone " $MAC_LIST | xargs | cut -d' ' -f3)
	OLD_APP_IP=$(grep -E "app-cs " $MAC_LIST | grep -v 'clone' | xargs | cut -d' ' -f3)
    
	sed -i "s/$OLD_APP_IP/$APP_IP/" $PGDATA/pg_hba.conf
    
	echo "Replace IP $OLD_APP_IP->$APP_IP in pg_hba.conf"    	
fi

if [ $TYPE == "web-srv" ]
then
	WEB_DIR=/var/www/1c
	
	APP_HOST=$(grep -E "app-cs .* clone " $MAC_LIST | xargs | cut -d' ' -f4)
	OLD_APP_HOST=$(grep -E "app-cs " $MAC_LIST | grep -v 'clone' | xargs | cut -d' ' -f4)
    
	find $WEB_DIR -type f -exec sed -i "s/$OLD_APP_HOST/$APP_HOST/g" {} \+
    
	echo "Replace hostname $OLD_APP_HOST->$APP_HOST in $WEB_DIR/*/*.vrd"    	
fi
