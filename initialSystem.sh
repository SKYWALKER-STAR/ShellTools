#!/bin/bash

######################################
#Create Date: 2023/02/26             #
#Last modify date: 2024/04/02	     #
#Description: Linux初始话脚本        # 
#Author: ming                        #
######################################

#######################################
# Some assitant function              #
#######################################

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


#Variable1_ErrorCode
#Variable2_ErrorCMD
#Variable3_ErrorMessage
function ERROR()
{
	if [[ $1 -eq 1 ]]
	then
		printFailMessage "$2":"$3"
	fi
}

#Variable1_returnCode
#Variable2_Message
function SUCCESS()
{
	if [[ $1 -eq 0 ]]
	then
		printOKMessage $2
	fi		
}

#######################################
# Modify hostName                     #
#######################################

function _get_ip_address()
{
	IPADDRESS=`ip addr show | egrep inet | egrep -v "127.0.0.1" | awk -F" " '{print $2}' | egrep "[1-9]{1,3}\.[1-9]{1,3}\.[1-9]{1,3}\.[1-9]{1,3}" | awk -F "/" '{print $1}'`
	IPADDRESS=($(echo $IPADDRESS | tr ' ' ' '))
	IPNUMBER=${#IPADDRESS[@]}

	if [[ $IPNUMBER -gt 1 ]]
	then
		IPADDRESS="${IPADDRESS[0]}"
	else
		IPADDRESS="$IPADDRESS"
	fi
}

function SetHostName()
{
	#printOrange
	#echo "Set hostname..."
	#printWhite

	#获取主机IP，如果有多个IP，则取第一个
	IPADDRESS=`ip addr show | egrep inet | egrep -v "127.0.0.1" | awk -F" " '{print $2}' | egrep "[0-9]{2,3}\.[0-9]{2,3}\.[0-9]{2,3}\.[0-9]{2,3}" | awk -F "/" '{print $1}'`
	IPADDRESS=($(echo $IPADDRESS | tr ' ' ' '))
	IPNUMBER=${#IPADDRESS[@]}

	if [[ $IPNUMBER -gt 1 ]]
	then
		HOSTNAME="node-"${IPADDRESS[0]}
	else
		HOSTNAME="node-"$IPADDRESS
	fi

	hostnamectl set-hostname $HOSTNAME
	printOKMessage "Set Host name to:$HOSTNAME"
	
}

#######################################
# Synchronization time zone           #
#######################################
function SetTimeZone()
{
	#printOrange
	#echo "Synchronizing timezone"
	#printWhite

	TIMEZONE="/usr/share/zoneinfo/Asia/Shanghai"
	
	
	rm -rf /etc/localtime
	let FLAG1=$?
	ln -s $TIMEZONE /etc/localtime
	let FLAG2=$?

	if [[ $FLAG1 -eq 1 ]] || [[ $FLAG2 -eq 1 ]]
	then
		printFailMessage "Set timezone failed"
	else
		printOKMessage "Set Timezone to:`basename ${TIMEZONE}`"
	fi
	
}
######################################
# Handle disk partition		     #
######################################
DISKARR=()
declare -A DISKUNPARTED
#Variable1_Device
function is_Parted()
{
	FLAG=`lsblk  "/dev/$1" | awk 'END{print NR}'`
	let FLAG=$FLAG-1

	if [[ $FLAG -eq 1 ]]
	then
		return 0
	else
		return 1
	fi
	
}

function Unparted_Disk()
{
	
	LIST=`lsblk | grep "sd[a-z][^0-9]" | awk '{print $1}'`
	DISKARR=($LIST)
	
	let COUNT=0
	for i in ${DISKARR[*]}
	do
		is_Parted $i
		let PARTED=$?
		if [[ $PARTED -eq 0 ]]
		then
			DISKUNPARTED[$i]=0
			let COUNT=$COUNT+1
		fi
	done
}

#Variable1_JustParted
function Parted_Mark() 
{
	DISKUNPARTED[$1]=1
}

#Variable1_Diskname
function Partition_Fdisk()
{
	fdisk "/dev/$1"
	Parted_Mark $1
}

#Variable1_Diskname
function PartNumber()
{
	let NUMBER=`lsblk "/dev/$1" | grep 'sd[a-z]' | awk 'END{print NR}'`
	echo "From PartNumber:$NUMBER"
	return $NUMBER
}


#Variable1_DISKNAME
#Variable2_SECTORNUMBER
#Variable3_Vgname
#Variable4_Lvname
#Variable5_Lvsize

function Partition_LVM() 
{
	VGROUP=
	DISKNAME="/dev/$1"
	let TOTALPARTITION=$2
	let COUNT=1

	while [[ $COUNT -le $TOTALPARTITION ]]
	do
		pvcreate -ff $DISKNAME$COUNT
		VGROUP=$VGROUP" "$DISKNAME$COUNT
		let COUNT=$COUNT+1
	done

	echo $VGROUP
	read a
	vgcreate $3 $VGROUP
	if [[ $? -eq 0 ]]
	then
		printOKMessage "VG $3 create successfully"
	else
		printFailMessage "Failed vgcreate"
		exit 1
	fi

	lvcreate -L $5 -n $4 $3
	if [[ $? -eq  0 ]]
	then
		printOKMessage "LV $4 successfully"
	else
		printFileMessage "Failed lvcreate"
		exit 1
	fi

	mkfs.ext4 "/dev/$3/$4"
	if [[ $? -eq 1 ]]
	then
		printFailMessage "Failed mkfs /dev/$3/$4"
		exit 1
	fi
}

#Variable1_mountDevice
#Variable2_mountPoint
function LVM_Mount()
{
	mount $1 $2
	if [[ $? -eq 1 ]]
	then
		printFailMessage "Faile mount $1 to $2"
	fi
}

function Unparted_Print()
{
	echo "We have unparted disk:"
	for i in ${!DISKUNPARTED[*]}
	do
		if [[ ${DISKUNPARTED[$i]} -eq 0 ]]
		then
			#lsblk /dev/$i | awk '{print $1,$2}' | awk '{print NR==2}'
			echo $i
		fi
	done
}

function AllParted()
{
	let COUNT=0
	
	for i in ${!DISKUNPARTED[*]}
	do
		if [[ ${DISKUNPARTED[$i]} -eq 0 ]]
		then	
			let COUNT=$COUNT+1
		fi
	done
	return $COUNT
}

#Variable1_DISKNAME
function legalName()
{
	for i in ${!DISKUNPARTED[*]}
	do
		if [[ $1 ==  $i ]]
		then	
			return 0
		fi
	done

	return 1
}

function InitialSetup_Partition()
{
	printOrange
	echo "Start partition process"
	printWhite

	Unparted_Disk
	while true
	do
		AllParted
		let EMPTY=$?

		if [[ $EMPTY -eq 0 ]]
		then
			printGreen
			echo "No disks left to be pated"
			printWhite
			break;
		fi

		Unparted_Print
		echo -e "Please entry disk you want do partition(press q quit):\c"
		read DISKNAME

		if [[ $DISKNAME == "q" ]]
		then
			break
		else
			legalName $DISKNAME
		fi
		
		if [[ $? -eq 0 ]]
		then
			Partition_Fdisk $DISKNAME
			sleep 1

			let NUMBER=`lsblk /dev/$DISKNAME | grep "sd[a-z]" | awk "END{print NR}"`

			NUMBER=$((NUMBER-1))
			echo $NUMBER

			printOrange
			echo  "Creat LVM partition on /dev/$DISKNAME"
			printWhite
	
			echo -e "Entry vg name:\c"
			read VGNAME
			echo -e "Entry lv name:\c"
	
			read LVNAME
			echo -e "Entry lv size:\c"
			read LVSIZE

			echo -e "Entry mount point:\c"
			read MOUNTPOINT
	
			Partition_LVM $DISKNAME $NUMBER $VGNAME $LVNAME $LVSIZE

			LVM_Mount "/dev/$VGNAME/$LVNAME" $MOUNTPOINT
		else
			printRed
			echo "Illegal device name:$DISKNAME,please retry"
			printWhite
		fi
	done

	printOKMessage "DiskPartition completed"
	
}


#######################################
# Configure IP address                #
#######################################
function ConfigureNetWork()
{
	let FLAGERROR=0
	printOrange
	echo "Starting configuring network..."
	printWhite

	NETINTERFACE=`nmcli | awk 'NR==1' | awk '{print $1}' | sed 's/://'`
	
	printOrange
	echo "set network interface:$NETINTERFACE basics"
	printWhite
	
	CONFIGURATION_FILE="/etc/sysconfig/network-scripts/ifcfg-$NETINTERFACE"

	IPADDRESS=
	NETMASK=
	GATEWAY=
	DNS1=
	DNS2=

	echo -e "Entry static IPADDRESS:\c"
	read IPADDRESS
	CONFIGURE_IPADDRESS="\$a\IPADDR=$IPADDRESS"
	
	echo -e "Entry NetMask:\c"
	read NETMASK
	CONFIGURE_NETMASK="\$a\NETMASK=$NETMASK"
	
	echo -e "Entry GateWay:\c"
	read GATEWAY
	CONFIGURE_GATEWAY="\$a\GATEWAY=$GATEWAY"
	
	echo -e "Entry DNS1:\c"
	read DNS1
	CONFIGURE_DNS1="\$a\DNS1=$DNS1"
	
	echo -e "Entry DNS2:\c"
	read DNS2
	CONFIGURE_DNS2="\$a\DNS2=$DNS2"

	sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/' $CONFIGURATION_FILE
	sed -i $CONFIGURE_IPADDRESS $CONFIGURATION_FILE
	sed -i $CONFIGURE_NETMASK $CONFIGURATION_FILE
	sed -i $CONFIGURE_GATEWAY $CONFIGURATION_FILE
	sed -i $CONFIGURE_DNS1 $CONFIGURATION_FILE
	sed -i $CONFIGURE_DNS2 $CONFIGURATION_FILE
	printOKMessage "Network configuration complete"
}

#######################################
# Disable SELinux                     #
#######################################
function Disable_Selinux()
{

	grep -q "SELINUX=enforcing" /etc/selinux/config
	if [[ $? -eq 0 ]]
	then
		sed -i 's/SELINUX=enforcing/SELINUX=disable/g' /etc/selinux/config
	else
		grep -q SELINUX=disable /etc/selinux/config
		if [[ $? -eq 0 ]]
		then
			printOKMessage "SELINUX Already disabled"
		else
			sed -i '$a/SELINUX=disable' /etc/selinux/config
		fi
	fi

	printOKMessage "SELINUX is shut now"
}

#######################################
# Close FireWall                      #
#######################################
function ShutDownFireWall()
{
	systemctl stop firewalld
	if [[ $? -eq 0 ]]
	then
		printOKMessage "ShutDown firewall success"
	else
		printFaileMessage "ShutDown firewall failed"
	fi
}


#######################################
# Modify root passwd                  #
#######################################
function ModifyRoot_PassWord()
{
	printOrange
	echo "Set root passwords"
	printWhite

	PASSWORD=
	PASSWORD_CONFIRM=

	while true
	do
		echo -e "Please entry your root password:\c"
		stty -echo
		read PASSWORD
		stty echo

		echo
		echo -e "Confirm your root password:\c"
		stty -echo
		read PASSWORD_CONFIRM
		stty echo
		echo
	
		if [[ $PASSWORD  == $PASSWORD_CONFIRM ]]
		then	
			echo "$PASSWORD" | passwd --stdin root
			break
		else
			printFailMessage "Two passwrod not match,please retry"
			echo
		fi
	done

	printOKMessage "User Password set"
	
}

#######################################	
# Add user account                    #
# dev: for development                #
# w t: for operation                  #
# dsp: for program		      #
#######################################

function CreateUsers() 
{
	PASSWORD="yiming@123456"
	useradd dev -p $PASSWORD
	if [[ $? -eq 0 ]]
	then
		printOKMessage "Account dev created successfully,default password is ${PASSWORD}"
	fi
	useradd wt -p $PASSWORD
	if [[ $? -eq 0 ]]
	then
		printOKMessage "Account wt created successfully,default password is ${PASSWORD}"
	fi
	useradd dsp -p $PASSWORD
	if [[ $? -eq 0 ]]
	then
		printOKMessage "Account dsp created successfully,default password is ${PASSWORD}"
	fi
}



#########################################################
# Modify maximum connection number and opend flie number#
#########################################################
CONFIGFILE="/etc/security/limits.conf"
function ModifyHardNproc_Number()
{
	PATTERN="[#]\*\s*hard\s*noproc\s*[0-9]*"
	grep -q $PATTERN $CONFIGFILE
	if [[ $? -eq 0 ]]
	then
		sed -i "s/[#]\*\s*hard\s*noproc\s*[0-9]*/*  hard  noproc  1000/g"  $CONFIGFILE
	else
		sed -i '$a\*  hard  noproc  1000'  $CONFIGFILE
	fi
	
	printOKMessage "Hard noproc set to 1000"
}
function ModifySoftNproc_Number()
{
	PATTERN="[#]\*\s*soft\s*noproc\s*[0-9]*"
	grep -q $PATTERN $CONFIGFILE
	if [[ $? -eq 0 ]]
	then
		sed -i "s/[#]\*\s*soft\s*noproc\s*[0-9]*/*  soft  noproc  1000/g"  $CONFIGFILE
	else
		sed -i '$a\*  soft  noproc  1000'  $CONFIGFILE
	fi

	printOKMessage "Soft noproc set to 1000"
}

function ModifyHardNfile_Number()
{
	PATTERN="[#]\*\s*hard\s*nofile\s*[0-9]*"
	grep -q $PATTERN $CONFIGFILE
	if [[ $? -eq 0 ]]
	then
		sed -i "s/[#]\*\s*hard\s*nofile\s*[0-9]*/*  hard  nofile  1000/g"  $CONFIGFILE
	else
		sed -i '$a\*  hard  nofile  1000'  $CONFIGFILE
	fi
	printOKMessage "Hard file set to 1000"
}
function ModifySoftNfile_Number()
{
	PATTERN="[#]\*\s*soft\s*nofile\s*[0-9]*"
	grep -q $PATTERN $CONFIGFILE
	if [[ $? -eq 0 ]]
	then
		sed -i "s/[#]\*\s*soft\s*nofile\s*[0-9]*/*  soft    nofile  1000/g"  $CONFIGFILE
	else
		sed -i '$a\*  hard  nofile    1000'  $CONFIGFILE
	fi
	printOKMessage "Soft file set to 1000"
}

function FileProcConfirm()
{
	sed -i "$a\session required /lib64/security/pam_limits.so" /etc/pam.d/login
	printOKMessage "Modified"
}

#Variable1_ConfigFile
function TCPIP_Related()
{

	if [[ $? -eq 1 ]]
	then
		printFailMessage "Set TCP Maximum connection failed"
		return $?
	fi
	
	sed -i "\$a\net.ipv4.tcp_abort_on_overflow = 1" $1
	sed -i "\$a\net.ipv4.tcp_fin_timeout = 60" $1

	sed -i "\$a\net.ipv4.ip_local_port_range = 32768 60999" $1
	sed -i "\$a\net.ipv4.ip_local_reserved_ports = 22,8080,80,433,21" $1
	
	sysctl -p -q $1
	
	printOKMessage "Complete TCP/IP related configuration"

}

function doModifySecurity()
{
	ModifyHardNproc_Number
	ModifySoftNproc_Number
	ModifyHardNfile_Number
	ModifySoftNfile_Number
}


function doModifyKernel()
{
	touch "/etc/sysctl.d/01-sysctl.conf"
	CONFIGURATION_FILE="/etc/sysctl.d/01-sysctl.conf"
	
	echo "# Custom kernel tunable config file " > $CONFIGURATION_FILE
	TCPIP_Related $CONFIGURATION_FILE
}


#######################################
# Forbidden CTRL+ALT+DEL              #
#######################################
function ForbiddenCTRL_ALT_DEL()
{
	if [ -L "/usr/lib/systemd/system/ctrl-alt-del.target" ]
	then
		mv /usr/lib/systemd/system/ctrl-alt-del.target /usr/lib/systemd/system/ctrl-alt-del.target.bak
		if [[ $? -eq 0 ]]
		then
			printOKMessage "CTRL-ALT-DEL key banned"
		fi
	fi
}

#######################################
#  Coonfigure ssh related attributes  #
#######################################
CONFIGURATIONFILE="/etc/ssh/sshd_config"

function SSH_DisableEmptyPasswd()
{
	
	grep -q "[#]*PermitEmptyPasswords\s*yes" $CONFIGURATIONFILE
	let MATCH_YES=$?

	grep -q "[#]*PermitEmptyPasswords\s*no" $CONFIGURATIONFILE
	let MATCH_NO=$?

	if [[ $MATCH_YES -eq 0 ]]
	then
		sed -i "s/[#]*PermitEmptyPasswords\s*yes/PermitEmptyPasswords  no\n/g" $CONFIGURATIONFILE
	elif [[ $MATCH_NO -eq 0 ]]
	then
		sed -i "s/[#]*PermitEmptyPasswords\s*no/PermitEmptyPasswords   no\n/g" $CONFIGURATIONFILE
	else
		
		sed -i '$a\PermitEmptyPasswords no\n' $CONFIGURATIONFILE
	fi
	
}
function SSH_ModifyDefaultPort()
{
	PATTERN="[#]*Port\s[0-9]*"
		
	grep -q $PATTERN $CONFIGURATIONFILE
	
	if [[ $? -eq 0 ]]
	then
		sed -i "s/[#]*Port\s[0-9]*/Port 1234/g" $CONFIGURATIONFILE
	else
		sed -i '$a\Port 1234' $CONFIGURATIONFILE
	fi
}

function SSH_DisableRootLogin()
{
	PATTERN_YES="[#]*PermitRootLogin\s*yes"
	PATTERN_NO="[#]*PermitRootLogin\s*yes"

	grep -q $PATTERN_YES $CONFIGURATIONFILE
	let MATCH_YES=$?

	grep -q $PATTERN_NO $CONFIGURATIONFILE
	let MATCH_NO=$?

	if [[ $MATCH_YES -eq 0 ]]
	then
		sed -i "s/[#]*PermitRootLogin\s*yes/PermitRootLogin no\n/g" $CONFIGURATIONFILE
		ehco 
	elif [[ $MATCH_NO -eq 0 ]]
	then
		sed -i "s/[#]*PermitRootLogin\s*no/PermitRootLogin no\n/g" $CONFIGURATIONFILE
		echo 
	else
		sed -i '$a\PermitRootLogin no\n' $CONFIGURATIONFILE
	fi
	
}

function SSH_Configuration()
{

	systemctl restart sshd
	SSH_DisableEmptyPasswd
	printOKMessage "ssh-Disable empty passwords login"

	SSH_ModifyDefaultPort
	printOKMessage "ssh-Set ssh port to 1234"

	SSH_DisableRootLogin
	printOKMessage "ssh-Disable Root Login"

}

#######################################
# 对细节进行调整		      #
# 1. 命令行的用户及目录名称           #
#######################################

function misc()
{
	#自定义环境变量PS1
	_get_ip_address
	IP=$IPADDRESS
	PATTERN="'[\u@$IP \w]'"
	echo "export PS1=$PATTERN" >> /etc/profile
	printOKMessage "set PS1 to $PATTERN"


}

#######################################
# Start to run                        #
#######################################

echo "#################################"
echo "#  welcome to Initial script    #"
echo "#################################"

#TTY_Initial
#SetHostName
#SetTimeZone
#CreateUsers
##ModifyRoot_PassWord
#doModifySecurity
#doModifyKernel
#SSH_Configuration
#Disable_Selinux
#ShutDownFireWall
#ForbiddenCTRL_ALT_DEL
misc
#InitialSetup_Partition

echo "#################################"
echo "# Initial script complet        #"
echo "#################################"

#######################################
#Disable initial-setup.service.	      #
#######################################
#systemctl disable initial-setup.service
