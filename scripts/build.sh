#!/usr/bin/env bash

set -euo pipefail

: ${IMAGE:=asssaf/vcore}
: ${TARGET:=export-initramfs}
: ${ARCH:=aarch64}
: ${BUSYBOX_BINPKGS:=""}
: ${INSTALL_PACKAGES:=""}
: ${INSTALL_STAGE:=""}
: ${ROOTFS=""}
: ${OUTPUT_TAR:=""}
: ${OUTPUT_LOCAL:=""}

docker build -t ${IMAGE} \
	--target=${TARGET} \
        ${OUTPUT_TAR:+--output "type=tar,dest=$OUTPUT_TAR"} \
        ${OUTPUT_LOCAL:+--output "type=local,dest=$OUTPUT_LOCAL"} \
	--build-arg "ARCH=${ARCH}" \
	${BUSYBOX_BINPKGS:+--build-arg "BUSYBOX_BINPKGS=${BUSYBOX_BINPKGS}"} \
	${INSTALL_PACKAGES:+--build-arg "INSTALL_PACKAGES=${INSTALL_PACKAGES}"} \
	${INSTALL_STAGE:+--build-arg "INSTALL_STAGE=${INSTALL_STAGE}"} \
	${ROOTFS:+--build-arg "ROOTFS=${ROOTFS}"} \
	-f docker/Dockerfile \
	.
