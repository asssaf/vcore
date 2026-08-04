#!/bin/sh

set -eu

function run_service() {
	local DEVICE="$1"
	local BASE="/etc/sv"
	local SERVICE_TEMPLATE="getty@"
	local SERVICE="${SERVICE_TEMPLATE}${DEVICE}"
	local SERVICE_TEMPLATE_DIR="${BASE}/${SERVICE_TEMPLATE}"
	local SERVICE_DIR="${BASE}/${SERVICE}"

	cp -as "${SERVICE_TEMPLATE_DIR}" "${SERVICE_DIR}"
	rm -f "${SERVICE_DIR}/supervise" "${SERVICE_DIR}/log/supervise"

	ln -s "${SERVICE_DIR}" /var/service
}

for i in $(cat /proc/cmdline)
do
	case $i in
		getty=*)
			device=${i#*=}
			grep -q "^${device}:" /etc/inittab || run_service $device
		;;
	esac
done
