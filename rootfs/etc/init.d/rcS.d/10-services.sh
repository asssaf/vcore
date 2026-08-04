#!/bin/sh

set -eu

for SERVICE in busybox-klogd busybox-syslogd dhcpc busybox-ntpd
do
	ln -s "/etc/sv/${SERVICE}" /var/service
done
