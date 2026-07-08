#!/bin/sh

set -euo pipefail

: ${IMAGE:=asssaf/vcore-packages}
: ${TARGET:=export-package}
: ${OUTPUT_TAR:=""}
: ${OUTPUT_LOCAL:=""}
: ${HOST_PKG:=""}
: ${ARCH:=aarch64}

EXCLUDE="musl"


PKG="$1"
PKG_URL="$2"

[ "${PKG}" = "${EXCLUDE}" ] && return 0

if [[ ! "${PKG_URL}" = "http"* ]]
then
	HOST_PKG="${PKG_URL}"
fi

docker build -t ${IMAGE} \
	--target=${TARGET} \
	${OUTPUT_TAR:+--output "type=tar,dest=$OUTPUT_TAR"} \
	${OUTPUT_LOCAL:+--output "type=local,dest=$OUTPUT_LOCAL"} \
	--build-arg ARCH="${ARCH}" \
	--build-arg PKG="${PKG}" \
	--build-arg PKG_URL="${PKG_URL}" \
	${HOST_PKG:+--build-arg "HOST_PKG=${HOST_PKG}" --build-arg "PACKAGE_SOURCE_STAGE=copy-package"} \
	-f docker/Dockerfile \
	.
