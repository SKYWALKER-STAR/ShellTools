#/bin/bash
ENVFILE=`pwd`/env.sh
source $ENVFILE
source $FUNCTIONFILE

FILE_ARRAY=("/etc/login.defs" \
            "/etc/pam.d/system-auth" \
	    "/etc/profile" \
	    "/etc/shadow" \
	    "/etc/passwd" \
	    "/etc/group" \
	    "/etc/rsyslog.conf" \
	    "/etc/audit/auditd.conf" \
	    "/etc/audit/rules.d/audit.rules" \
#	    "/var/log/messages" \
#	    "/var/log/secure" \
	    "/var/log/cron" \
	    "/var/log/audit/audit.log" \
	    "/etc/logrotate.conf" \
	    "/etc/audit/rules.d/auditd.rule" \
	    "/etc/hosts.allow" \
	    "/etc/hosts.deny" \
	    "/etc/crontab" \
	    "/etc/redhat-release" \
	    "/etc/os-release" \
)

SERVER_ARRAY=("rsyslog"\
	"auditd"\
	"firewalld"\
	"iptables"\

)

for((i = 0;i < ${#FILE_ARRAY[@]};i++)) do
	catFile ${FILE_ARRAY[i]};
done
