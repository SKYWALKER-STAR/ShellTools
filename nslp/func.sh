#!/bin/bash

######################################
#Create Date: 2023/02/26             #
#Description: 等保测评      # 
#Author: ming                        #
######################################

#######################################
# Some assitant function              #
#######################################

source `pwd`/env.sh

function printRed()
{
	echo -e "\033[31;40m\c"
}

function printWhite()
{
	echo -e "\033[37;49m\c"
}

function printGreen()
{
	echo -e "\033[32;40m\c"
}

function printOrange()
{
	echo -e "\033[33;40m\c"
}

function printOKMessage()
{
	echo -e "[\c"
	printGreen
	echo -e "OK\c"
	printWhite
	echo -e "]\c"
	echo $1
}

function printFailMessage()
{
	echo -e "[\c"
	printRed
	echo -e "Failed\c"
	printWhite
	echo -e "]\c"
	echo $1
}

function TTY_Initial()
{
	stty erase "^H"
}


#######################################
#$1 目标文件			      #
#$2 标题			      #
#######################################
function printCuttingLineStarts()
{
	echo -e "---------------------------$2 starts---------------------------" >> $1
}

#######################################
#$1 目标文件			      #
#$2 标题			      #
#######################################

function printCuttingLineEnds()
{
	echo -e "---------------------------$2 ends---------------------------" >> $1
}

#######################################
#$1 源文件			      #
#$2 目标文件			      #
#$3 标题			      #
#######################################

function catFile()
{
	FILE=$1
	if [ -f $FILE ]; then

		printCuttingLineStarts $OUTPUTFILE "cat $FILE"
		cat "$FILE" >> $OUTPUTFILE
		printCuttingLineEnds  $OUTPUTFILE "cat $FILE"
		echo " " >> $OUTPUTFILE

		echo -e "cat $FILE to $OUTPUTFILE...\c"
		printGreen
		echo -e " ok"
		printWhite
	else
		printCuttingLineStarts $OUTPUTFILE "cat $FILE"
		echo "Empty" >> $OUTPUTFILE
		printCuttingLineEnds  $OUTPUTFILE "cat $FILE"
		echo " " >> $OUTPUTFILE

		echo -e "cat $FILE to $OUTPUTFILE...\c"
		printRed
		echo -e " no"
		printWhite
	fi
}

#######################################
#$1 服务名称			      #
#$2 目标输出文件		      #
#######################################

function serviceStatus()
{
	SERVICE=$1
	printCuttingLineStarts $OUTPUTFILE "service $SERVICE"
	service status $SERVICE >> $OUTPUTFILE
	printCuttingLineEnds $OUTPUTFILE "service $SERVICE"
}
