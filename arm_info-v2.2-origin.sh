#!/bin/bash

APPADMIN_PASS='***'   ###appadmin用户密码
ROOT_PASS='***'        #######root 密码
NTP_SERVER="10.0.0.1"       ####ntp服务器ip

#--------------------------------------------------
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
APPROOT=$(cd "$(dirname "$0")"; pwd)
cd $APPROOT
AUTORUN="no"
WORK_DIR=`pwd`

#### 函数区

CHK_TASK_USER(){
    [ $(id -u) != "0" ] && { echo -e "\e[31m请使用root账号执行本初始化脚本\e[0m"; exit 1; }
}


UPDATE_YUM(){ #安装操作系统依赖文件，完成操作系统命令自动补全
    yum install -y  make ntpdate lvm2 sysstat iostat wget telnet mlocate vim sysstat lsof ntpdate lrzsz rsync parted python-setuptools bash-completion* util-linux xfsprogs libselinux-python unzip tree gcc gcc-c++
}

HOSTS_NAME(){
    hostname="host-`ifconfig|grep inet |head -n 1 |awk '{print $2}'|sed 's/\./-/g'`"
    #修改主机名
    echo  $hostname >  /etc/hostname
    hostname $hostname
}

LVM(){
   echo -e '\033[31m---------------------------------\033[0m'
   echo -e "\033[36m注意事项：\033[0m"
   echo 
   echo -e "1)默认格式化挂载盘符是/dev/vdb."
   echo -e "2)确保/dev/vdb是空的，格式化后无法恢复."
   echo -e '\033[31m---------------------------------\033[0m'
   echo
   sleep 3
   read -p'准备格式化磁盘，请确认，输入 yes|y|YES|Y 格式化，输入其他跳过不执行:' name
   if [ $name == yes -o $name == y -o $name == Y -o $name == YES ]
   then
       yum install lvm2 -y
       pvcreate /dev/vdb
       vgcreate vgdata /dev/vdb
       lvcreate -l 100%FREE -n lvdata vgdata
       mkfs.xfs /dev/vgdata/lvdata
       mkdir /data
       mount /dev/vgdata/lvdata /data
       cp /etc/fstab /etc/fstab.bk
       echo '/dev/vgdata/lvdata   /data/  xfs  defaults  0 0' >> /etc/fstab 
   else
       echo "你输入的是：$name 不执行格式化，如有需要，手动执行"
       sleep 3
   fi
}


CREATE_DIR(){ #创建操作系统常规目录
    source  /etc/profile
    umask 0022 
    mkdir -p /data/{apps,bak,cert,cron,logs,share,sh,software,sdk,src,temp} && echo -e "/data标准化目录已创建"
}

SET_VIM(){ #vim编辑器自动缩进
    echo 'set ts=4' >> /etc/vimrc && echo -e "vim编辑器自动缩进已设置"
}

DISABLE_SELINUX(){ #selinux禁用
    if [[ -s /etc/selinux/config ]];then
        if ! grep "^SELINUX=disabled" /etc/selinux/config >& /dev/null
        then
            sed -i "s/^SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
        fi
    else
        echo -e "selinux已禁用"
        return
    fi
    if grep "^SELINUX=disabled" /etc/selinux/config >& /dev/null
    then
        echo -e "selinux已禁用"
    else
        echo -e "【警告】selinux仍开启，请手动处理"
    fi
}


CHK_UTF(){ #切换字符集:LANG="en_US.UTF-8"
        grep 'LANG="zh_CN' /etc/locale.conf
        if [ $? -ne 0 ];then
	    sed -i 's/^LANG=\"[A-Za-z0-9].*\"/LANG=\"en_US\.UTF-8\"/g' /etc/locale.conf
	    source /etc/locale.conf
            echo -e "字符模式修改为en_US.UTF-8"
        else
	    echo -e "字符模式已是en_US.UTF-8"
	fi
}

CHK_ZONE(){ #时区配置:Asia/Shanghai
        timedatectl | grep 'Asia\/Shanghai' >/dev/null
        if [ $? = 0 ];then
            echo -e "系统时区修改为Asia/Shanghai"
        else
            timedatectl set-timezone Asia/Shanghai
            echo -e "系统时区已是Asia/Shanghai"
        fi
}

DISABLE_CAD() { #关闭Crtl+Alt+Delete三键重启
        file="/usr/lib/systemd/system/ctrl-alt-del.target"
        if [ -f "$file" ]; then
            rm -rf /usr/lib/systemd/system/ctrl-alt-del.target && echo -e "Ctrl-Alt-Del已关闭"
        else
            echo -e "Ctrl-Alt-Del已关闭"
        fi
}


CHK_OPERATOR(){ #检查appadmin及appops用户
    grep "appadmin" /etc/passwd
    if [[ $? -eq 0 ]];then
        chown -R appadmin:appadmin /data/
        echo -e "appadmin用户已存在"
    else
        groupadd appadmin -g 2000 && echo -e "appadmin用户组已创建"
        useradd appadmin -d /home/appadmin -g appadmin -u 2000  -c "Digitalgd appadmin" && echo -e "appadmin用户已创建"
        echo -e "$APPADMIN_PASS" | passwd appadmin --stdin && echo -e "appadmin用户已更新密码"
        chown -R appadmin:appadmin /data/
        chmod 755 -R  /data/
    fi

    grep "appops" /etc/passwd
    if [[ $? -eq 0 ]];then
        echo -e "appops用户已存在"
    else
        groupadd appops -g 2001 && echo -e "appops用户组已创建"
        useradd -g appops -s /sbin/nologin -M appops
    fi

    #添加用户sudo权限
    chmod 777 /etc/sudoers
    echo "appadmin ALL=(ALL)       NOPASSWD:ALL" >> /etc/sudoers
    chmod 440 /etc/sudoers
    #更新root密码
    echo -e "$ROOT_PASS" | passwd root --stdin && echo -e "root用户已更新密码"

    ##禁止root登录（有风险，要确保普通用户能登录）
    sed -i '/PermitRootLogin/s/yes/no/g' /etc/ssh/sshd_config
    systemctl restart sshd 
}


CHK_OPEN_LIMIT(){ #配置系统最大文件打开数
        cp -af /etc/pam.d/login /etc/pam.d/login.backup
        grep "session    required     /lib64/security/pam_limits.so" /etc/pam.d/login | grep -v "^#"
        if [ $? -ne 0 ];then
            echo "session    required     /lib64/security/pam_limits.so" >> /etc/pam.d/login
        fi
        grep "session    required     pam_limits.so" /etc/pam.d/login | grep -v "^#"
        if [ $? -ne 0 ];then
            echo "session    required     pam_limits.so" >> /etc/pam.d/login
        fi
        echo -e "系统最大文件打开数已修改"
        cp -af /etc/systemd/system.conf /etc/systemd/system.conf.backup
        if [ -f /etc/systemd/system.conf ];then
            grep "^DefaultLimitNOFILE" /etc/systemd/system.conf | grep -v "^#"
            if [ $? -ne 0 ];then
                echo "DefaultLimitCORE=infinity" >>/etc/systemd/system.conf
                echo "DefaultLimitNOFILE=1024000" >>/etc/systemd/system.conf
                echo "DefaultLimitNPROC=1024000" >>/etc/systemd/system.conf
                systemctl daemon-reexec
            fi
        fi
        echo -e "系统网络配置参数已优化"
}


CHK_SECURITY_AUDIT(){ #安全基线审计配置
    echo "\$InputFileSeverity info" >> /etc/rsyslog.conf
    echo "kern.warning;*.err;authpriv.none\t@loghost" >> /etc/rsyslog.conf
    echo "*.info;mail.none;authpriv.none;cron.none\t@loghost" >> /etc/rsyslog.conf
    echo "*.emerg @loghost\t" >> /etc/rsyslog.conf
    echo -e "rsyslog安全基线审计已优化"
}

CHK_KERNEL(){ #系统内核参数优化
    cp -af /etc/sysctl.conf /etc/sysctl.conf.apps
    cat >> /etc/sysctl.conf <<EOF
fs.nr_open = 2048000
net.core.netdev_max_backlog = 262144
net.core.rmem_default = 8388608
net.core.rmem_max = 41943040
net.core.somaxconn = 262144
net.core.wmem_default = 8388608
net.core.wmem_max = 41943040
net.ipv4.conf.enp3s0.accept_redirects = 0
net.ipv4.conf.enp3s0.accept_source_route = 0
net.ipv4.conf.enp3s0.secure_redirects = 1
net.ipv4.conf.enp3s0.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.secure_redirects = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.secure_redirects = 1
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.accept_redirects = 0
net.ipv4.conf.lo.accept_source_route = 0
net.ipv4.conf.lo.secure_redirects = 1
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_local_port_range = 4096 65535
net.ipv4.ip_local_reserved_ports=8060,8080,8081,8082,9000,9080,9090,60020,12000-12100
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_rmem = 8388608 8388608 33554432
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 524288 524288 33554432
vm.dirty_background_bytes = 104857600
vm.swappiness = 5
EOF
    echo -e "系统内核参数已优化"

[ ! -f /etc/security/limits.conf.bak ] && /bin/cp /etc/security/limits.conf /etc/security/limits.conf.bak
cat > /etc/security/limits.conf << EOF
  * soft core  unlimited
  * hard core  unlimited
  * soft fsize unlimited
  * hard fsize unlimited
  * soft data  unlimited
  * hard data  unlimited
  * soft nproc 1024000
  * hard nproc 1024000
  * soft stack unlimited
  * hard stack unlimited
  * soft nofile 1024000
  * hard nofile 1024000
EOF

    echo -e "\e[32m系统内核参数(数据库侧)已优化\e[32m"
}


CHK_NTP(){ #时间同步配置:192.168.148.101
        systemctl stop ntpd
        systemctl disable ntpd
        grep "ntpdate" /var/spool/cron/root
        if [ $? -ne 0 ];then
            echo "10 * * * * /usr/sbin/ntpdate $NTP_SERVER;/sbin/hwclock -w" >> /var/spool/cron/root
            /usr/sbin/ntpdate $NTP_SERVER;/sbin/hwclock -w
            echo -e "时间同步服务器修改为$NTP_SERVER"
        else
            echo -e "时间同步服务器已经配置"
        fi
}

UPDATE_LOGIN(){
	sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/' /etc/login.defs
	#登录密码最短修改时间，增加可以防止非法用户短期更改多次
	sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS\t7/' /etc/login.defs
	#账户密码密码强度，最小8位数
	sed -i 's/PASS_MIN_LEN.*/PASS_MIN_LEN\t8/' /etc/login.defs
	#登录密码过期提前7天提示修改
	sed -i 's/PASS_WARN_AGE.*/PASS_WARN_AGE\t7/' /etc/login.defs
	sed -i '0,/99999/s//90/' /etc/shadow
}

UPDATE_AUTH(){
sed -i '/password.*required.*pam_deny.so/ i\auth required pam_tally2.so onerr=fail deny=5 unlock_time=180 even_deny_root root_unlock_time=300' /etc/pam.d/system-auth
sed -i '4 i\auth       required       pam_tally2.so  onerr=fail deny=5 unlock_time=180 even_deny_root root_unlock_time=300' /etc/pam.d/system-auth
sed -i '/account.*required.*pam_unix.so/i\account\t    required\t  pam_tally2.so' /etc/pam.d/system-auth

echo '
# 监视系统文件
-w /etc/sysconfig -p rwxa
-w /etc/ssh/sshd_config -p rwxa
-w /etc/hosts -p wa
-w /etc/hosts.deny -p wa
-w /etc/hosts.allows -p wa
# 监视审计配置文件
-w /etc/rsyslog.conf -p rwxap
-w /etc/audit/audit.rules -p rwxa 
-w /etc/audit/auditd.conf -p rwxa
# 监视密码文件
-w /etc/group -p wa
-w /etc/passwd -p wa
-w /etc/shadow -p rwxa
-w /etc/sudoers -p wa
# 监视环境文件
-w /etc/profile -p wa
-w /etc/bashrc -p wa
-w /etc/profile.d -p rwxa
# 监视定时任务cron配置文件
-w /etc/cron.d -p wa
-w /etc/cron.daily -p wa
-w /etc/cron.hourly -p wa
-w /etc/cron.monthly -p wa
-w /etc/cron.weekly -p wa
' >> /etc/audit/rules.d/auditd.rule

}

 ##修改logrotate 配置，系统日志默认保存6个月
UPDATE_LOGCONF(){
  sed -i 's/rotate 4/rotate 27/g' /etc/logrotate.conf
  sed -i 's/rotate 1/rotate 6/g' /etc/logrotate.conf
}

# Security Configuration
function SSH_CONFIG_MISC() {

	sed -i "/*.Protocol.*/d" $CONFIGURATIONFILE
	sed -i "/*.X11Forwarding.*/d" $CONFIGURATIONFILE
	sed -i "/*.IgnoreRhosts.*/d" $CONFIGURATIONFILE
	sed -i "/*.RhostsRSAAuthentication.*/d" $CONFIGURATIONFILE
	sed -i "/*.HostbasedAuthentication.*/d" $CONFIGURATIONFILE
	sed -i "/*.PermitRootLogin.*/d" $CONFIGURATIONFILE
	sed -i "/*.PermitEmptyPasswords.*/d" $CONFIGURATIONFILE
	sed -i "/*.s.*/d" $CONFIGURATIONFILE

	sed -i '$a Protocol 2' $CONFIGURATIONFILE
	sed -i '$a X11Forwarding yes' $CONFIGURATIONFILE
	sed -i '$a IgnoreRhosts yes' $CONFIGURATIONFILE
	sed -i '$a RhostsRSAAuthentication no' $CONFIGURATIONFILE
	sed -i '$a HostbasedAuthentication no' $CONFIGURATIONFILE
	sed -i '$a PermitRootLogin no' $CONFIGURATIONFILE
	sed -i '$a PermitEmptyPasswords no' $CONFIGURATIONFILE
	sed -i '$a Banner /etc/motd' $CONFIGURATIONFILE

	printOKMessage "Config sshd configuration succcessed"
}

function  PASSWD_DATE_RELATED() {
	CONFIGFILE="/etc/login.defs"

	sed -i "/.*PASS_MAX_DAYS.*/d" $CONFIGFILE
	sed -i "/.*PASS_MIN_DAYS.*/d" $CONFIGFILE
	sed -i "/.*PASS_WARN_AGE.*/d" $CONFIGFILE

	sed -i '$a PASS_MAX_DAYS 180' $CONFIGFILE
	sed -i '$a PASS_MIN_DAYS 90' $CONFIGFILE
	sed -i '$a PASS_WARN_AGE 120' $CONFIGFILE

	printOKMessage "Config password lifecycle successed"

}

function SET_UMASK() {
	CONFIGFILE="/etc/profile"

	sed -i "/.*umask 0027.*/d" $CONFIGFILE
	sed -i '$a umask 0027' $CONFIGFILE

	printOKMessage "Set umask to 0027"
}

function SET_HISTORY_TIMESTAMP() {
	CONFIGFILE="/etc/profile"

	sed -i "/.export HISTTIMEFORMAT*/d" $CONFIGFILE
	sed -i '$a export HISTIMEFORMAT="%F %F"' $CONFIGFILE

	printOKMessage "Set history timestamp successed"
}

function CONFIG_SYSLOG() {
	CONFIGFILE='/etc/syslog.conf'

	if [[ -f $CONFIGFILE ]]
	then
		sed -i '$a authpriv.*	/var/log/secure' $CONFIGFILE
	else
		touch $CONFIGFILE
		sed -i '$a authpriv.*	/var/log/secure' $CONFIGFILE
	fi

	printOKMessage "Config $CONFIGFILE successed"
}


function SET_PASSWORD_POLICY() {
	CONFIGFILE='/etc/pam.d/system-auth'

	sed -i '$a password	requisite	pam_cracklib.so	minlen=6 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1'

	printOKMessage "Config password complex policy successed"

}

function SECURITY_ENHANCE {
	SSH_CONFIG_MISC
	PASSWD_DATE_RELATED
	SET_UMASK
	SET_HISTORY_TIMESTAMP
	CONFIG_SYSLOG
	SET_PASSWORD_POLICY
}


APPS(){
CHK_TASK_USER
UPDATE_YUM
HOSTS_NAME
LVM
CREATE_DIR
SET_VIM
DISABLE_SELINUX
CHK_UTF
CHK_ZONE
DISABLE_CAD
CHK_OPERATOR
CHK_OPEN_LIMIT
CHK_SECURITY_AUDIT
CHK_KERNEL
CHK_NTP
UPDATE_LOGIN
UPDATE_AUTH
UPDATE_LOGCONF
SECURITY_ENHANCE
 echo "生产环境服务器已完成初始化"
}

APPS
