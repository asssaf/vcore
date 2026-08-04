#!/bin/sh

set -eu

for SERVICE in gadget sshd
do
	ln -s "/etc/sv/${SERVICE}" /var/service
done
