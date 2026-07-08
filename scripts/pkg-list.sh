#!/bin/sh

set -euo pipefail

: ${IMAGE:=asssaf/vcore-package-list}
: ${ARCH:=aarch64}
: ${OUTPUT_TAR:=""}
: ${OUTPUT_LOCAL:=""}

docker build -t ${IMAGE} \
	--target=export-package-list \
	${OUTPUT_TAR:+--output "type=tar,dest=$OUTPUT_TAR"} \
	${OUTPUT_LOCAL:+--output "type=local,dest=$OUTPUT_LOCAL"} \
	--build-arg ARCH=${ARCH} \
	--build-arg INSTALL_PACKAGES="$*" \
	-f docker/Dockerfile \
	--progress plain \
	.
