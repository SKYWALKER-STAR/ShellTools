#!/bin/bash

NEW_PREFIX=/usr/local/mingssh
OLD_PREFIX=/bin

#判断是否是Root用户
if [[ `id -u` != 0 ]]
then
	echo "please run $0 as root"
	exit
fi

#递归遍历所有目录下的文件
function getDir()
{
	for element in `ls $1`
	do
		file=$1"/"$element
		if [ -d $file ]
		then
			getDir $file
		else

			#去掉前缀路径，只保留文件名称
			onlyFile=`basename $file`

			#备份旧ssh相关文件
			if [ -f "$OLD_PREFIX/$onlyFile" ]
			then
				echo "Copy $OLD_PREFIX/$onlyFile to $OLD_PREFIX/$onlyFile-`date '+%Y-%m-%d'`"
				cp -ra $OLD_PREFIX/$onlyFile $OLD_PREFIX/$onlyFile-`date '+%Y-%m-%d'`
			fi

			#拷贝新的ssh相关文件到旧目录中
			echo "Copy $file to $OLD_PREFIX/$onlyFile"
			cp -ra $file $OLD_PREFIX/$onlyFile
		fi
	done
}

getDir $NEW_PREFIX
