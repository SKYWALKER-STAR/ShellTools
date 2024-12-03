#!/bin/sh

#################################################
#@Usage: 解压缩脚本
#@Author: Ming
#@Lastmodify Date: 2024-12-03
#################################################
file=$1
dest=$2
format=("tar" "gz" "zip")

if [[ `id -u` -ne 0 ]]
then
	echo -ne "\033[31;40m\c"
	echo -ne "[ERROR]"
	echo -ne "\033[37;49m\c"
	echo -e "Excute as root please"
	exit
fi

if [[ $@ -ne 2 ]]
then
	echo -ne "\033[33;40m\c"
	echo -ne "[WARN]"
	echo -ne "\033[37;49m\c"
	echo "usage $0 [filename] [dest dir]"
	exit
fi

for v in ${format[@]};
do
	if [ "${file##*.}"x = ${v}x ];
	then
		suffix=$v
		break
	fi
done

case $v in
   "tar")
	   tar -xvf $1 -C $2
	   ;;
   "zip")
	   unzip -d $1 -d $2
	   ;;
   "gz")
	   tar -xvf $1 -C $2
	   ;;
   "tgz")
	   tar -zxvf $1 -C $2

   *)
	   ;;
esac

