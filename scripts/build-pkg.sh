#!/bin/sh

set -euo pipefail

: ${IMAGE:=asssaf/vcore-packages}
: ${ARCH:=aarch64}
: ${OUTPUT_TAR:=""}
: ${OUTPUT_LOCAL:=""}

PKG="$1"

docker build -t ${IMAGE} \
	--target=export-binpkgs \
	${OUTPUT_TAR:+--output "type=tar,dest=$OUTPUT_TAR"} \
	${OUTPUT_LOCAL:+--output "type=local,dest=$OUTPUT_LOCAL"} \
	--build-arg ARCH="${ARCH}" \
	--build-arg PKG="${PKG}" \
	-f docker/Dockerfile \
	.
