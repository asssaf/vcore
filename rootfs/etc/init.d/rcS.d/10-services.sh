#!/bin/sh
# shuck:disable-file=X025,X052

set -eu

DEFAULT_SERVICES="busybox-klogd busybox-syslogd busybox-ntpd"

function get_services() {
	echo $DEFAULT_SERVICES

	read -r cmdline < /proc/cmdline
	set -- $cmdline

	for i in "$@"
	do
        	case $i in
                	services=*)
                        	services=${i#*=}
				echo ${services//,/ }
                	;;
        	esac
	done
}


for SERVICE in $(get_services)
do
	ln -s "/etc/sv/${SERVICE}" /var/service
done
