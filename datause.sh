#!/bin/bash
##################################################
#@usage: 使用Ansible的时候可能会需要用到的配置设置
#@author: ming
#@lastomodify date: 2024-08-30
##################################################

########################################################
#建立应用名称与应用端口的dictionary,这种方式非常方便巡检
########################################################

app_name_1="app_name_1"
app_name_2="app_name_2"
app_name_3="app_name_3" 

declare -A portDic

portDic[$app_name_1]="port1"
portDic[$app_name_2]="port2"
portDic[$app_name_3]="port3"

#########################################
#遍历dictionary,是一个示例,有需要时可参考
#########################################
for key in $(echo ${!portDic[*]});do
	echo "$key:${portDic[$key]}"
done

#################################################
#ansible 相关变量
#################################################
PWD=`pwd`
HOMEDIR=`dirname $PWD`
HOSTSFILE=$HOMEDIR/hosts
OPDATE=`date +%Y-%m-%d`
COMMNAD=
