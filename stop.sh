#!/bin/bash

if [ `id -u` -ne 0 ];
then
	echo "Error:$0:This script need root permision to run with"
	exit
fi

if [ $# -eq 0 ]
then
	echo "Usage: $0 PORTS..."
	exit
fi

OR_SIMBLE="\|"
APP_BASE_PATH=/home/ming/run/
APP_START_COMMAND=

APP_PORTS=($*)

declare -i PORT_COUNTER
PORT_COUNTER=${#APP_PORTS[*]}
PORT_COUNTER=$PORT_COUNTER-1

for i in `seq 0 $PORT_COUNTER`
do
	if [[ -z $TPORTS ]]
	then
		TPORTS=${APP_PORTS[i]}
	else
		TPORTS=${TPORTS}${OR_SIMBLE}${APP_PORTS[i]}
	fi
done

TARGET_APPS=`netstat -ntlp | grep $TPORTS | awk '{print $7}'`
array=${TARGET_APPS}
for i in ${TARGET_APPS[@]}
do
	PID=${i/\/[a-zA-Z]*/""}
	kill -9 $PID
done
