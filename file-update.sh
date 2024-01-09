#!/bin/bash

NEW_PREFIX=/usr/local
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

			#获取文件完整父目录路径
			baseDir=`echo $file|sed s/$onlyFile//g`

			#获取文件上一级目录名称
			parentDir=`basename $baseDir`


			#备份旧ssh相关文件
			if [ -f "$OLD_PREFIX/$parentDir/$onlyFile" ]
			then
				echo -e "\e[32mCopy $OLD_PREFIX/$parentDir/$onlyFile to $OLD_PREFIX/$parentDir/$onlyFile-`date '+%Y-%m-%d'`\e[0m"
				cp -ra $OLD_PREFIX/$parentDir/$onlyFile $OLD_PREFIX/$parentDir/$onlyFile-`date '+%Y-%m-%d'`
			else
				echo -e "\e[31mError:$OLD_PREFIX/$parentDir/$onlyFile not exists\e[0m"
			fi

			#拷贝新的ssh相关文件到旧目录中
			echo -e "\e[32mCopy $file to $OLD_PREFIX/$onlyFile[0m"
			cp -ra $file $OLD_PREFIX/$parentDir/$onlyFile
		fi
	done
}

getDir $NEW_PREFIX
