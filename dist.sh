#!/bin/bash
#Usage: 分发文件到其他主机
#Create Date: 2024/01/11
#Brief: 将指定的文件分发到相应的主机中,脚本接受三个参数，第一个参数是想要分发的文件，第二个参数是目的主机IP，脚本将逐行读取该文件，第三个参数是目标端口，脚本将使用第二个参数中指定的主机IP与第三个参数组成目的地址，默认的端口为23

#SRC_FILE: 想要分发的文件
#HOST_FILE: 主机IP文件
#PORT:主机端口

HOST_FILE=
SRC_FILE=
PORT=22

if [ $# -ne 3 ]
then
	echo -e "Usage:$0 [source_file] [host_file] [port]"
	exit
fi

if [ -f $1 ]
then
	SRC_FILE=$1
fi

if [ -f $2 ]
then	
	HOST_FILE=$2
fi

PORT=$3

for i in `cat $HOST_FILE`
do
	echo "Send $SRC_FILE to $i:$PORT:/tmp"
	scp -P $PORT $SRC_FILE $i:/tmp
done
