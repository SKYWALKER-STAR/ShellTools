#!/bin/bash

#################################################
#@Usage: Nginx操作脚本,可结合Ansible命令使用
#@Author: Ming
#@Lastmodify Date: 2024-08-30
#################################################

NGINX_HOME=/path/to/nginx/dir
NGINX_CONF=$NGINX_HOME/conf
NGINX_SBIN=$NGINX_HOME/sbin

PWD=`pwd`
HOMEDIR=`dirname $PWD`
HOSTSFILE=$HOMEDIR/hosts

OPDATE=`date +%Y-%m-%d`
COMMNAD=

if [ $# -eq 0 ];
then
	echo "Usage: $0 -c [command]"
	exit
fi

while getopts "c:" optname
do
	case "$optname" in 
		"c")
			COMMAND=$OPTARG
			;;
		*)
			 "Usage: $0 -c [command]"
			exit
			;;
	esac
done
