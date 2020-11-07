#!/bin/bash
#1
#Файл настроек
MAC_LIST=/etc/vm-clone/maclist.txt

#Имя интерфейса
DEV=$(ip a show scope link | head -n1 | cut -d':' -f2 | xargs)

#Конфигурационный файл настройки сети
IF_CONF=/etc/sysconfig/network-scripts/ifcfg-$DEV

#Текущий MAC адрес 
CUR_MAC=$(ip a show $DEV | head -n2 | tail -n1 | awk '{print $2}')

#Текущий IPv4
CUR_IP=$(cat $IF_CONF | grep 'IPADDR=' | cut -d'"' -f2)

#Текущее имя хоста
CUR_HOST=$(hostname)

#Если MAC есть в файле, то это продакшин
if grep -q "$CUR_MAC" $MAC_LIST
then
    exit 0
fi

TYPE=$(grep $CUR_IP $MAC_LIST | xargs | cut -d' ' -f1)
MAC_F=$(grep $CUR_IP $MAC_LIST | xargs | cut -d' ' -f2)

#Если тестовый узел уже настроен, то ничего делать не надо
if [ $MAC_F == "test" ]
then
    exit 0
fi

IP=$(grep -E "$TYPE .* test " $MAC_LIST | xargs | cut -d' ' -f3)
HOST=$(grep -E "$TYPE .* test " $MAC_LIST | xargs | cut -d' ' -f4)


echo "$DEV $CUR_MAC $CUR_IP $CUR_HOST"


if [ $IP != $CUR_IP ]
then
    sed -i -r "s/^IPADDR=.+/IPADDR=\"${IP}\"/" $IF_CONF
	echo "setting IP=$IP"
fi

if [ $HOST != $CUR_HOST ]
then
    echo $HOST > /etc/hostname
	echo "setting HOST=$HOST"	
fi

if [ $TYPE == "app" ]
then
    rm -rf /home/usr1cv8/.1cv8
	echo "remove cluster 1C"	
fi
