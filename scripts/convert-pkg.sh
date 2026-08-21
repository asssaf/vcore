#!/bin/sh

set -euo pipefail

: ${IMAGE:=asssaf/vcore-packages}
: ${TARGET:=export-package}
: ${OUTPUT_TAR:=""}
: ${OUTPUT_LOCAL:=""}
: ${HOST_PKG:=""}
: ${ARCH:=aarch64}
: ${PACKAGE_SOURCE_STAGE:=""}

EXCLUDE="musl"


PKG="$1"

[ "${PKG}" = "${EXCLUDE}" ] && return 0

docker build -t ${IMAGE} \
	--target=${TARGET} \
	${OUTPUT_TAR:+--output "type=tar,dest=$OUTPUT_TAR"} \
	${OUTPUT_LOCAL:+--output "type=local,dest=$OUTPUT_LOCAL"} \
	--build-arg ARCH="${ARCH}" \
	--build-arg PKG="${PKG}" \
	${PACKAGE_SOURCE_STAGE:+--build-arg "PACKAGE_SOURCE_STAGE=${PACKAGE_SOURCE_STAGE}"} \
	-f docker/Dockerfile \
	.
