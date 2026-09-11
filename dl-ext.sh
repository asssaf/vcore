#!/bin/sh

set -eux

: ${ARCH?:is required}
: ${PKG_REPO?:is required}
: ${EXT?:is required}
: ${OUTPUT:="."}


function dl_ext() {
	local EXT="$1"
	[ -e "${OUTPUT}/${EXT}.vcz" ] && return 0

	echo "Fetching ${EXT}..."
	TOKEN="$(wget -O - "https://ghcr.io/token?scope=repository:${PKG_REPO}-${EXT}:pull" | sed 's/{"token":"\(.*\)"}/\1/')"
	[ -z "$TOKEN" ] && return 1

	DIGEST="$(wget --header "Authorization: Bearer $TOKEN" -O - "https://ghcr.io/v2/${PKG_REPO}-${EXT}/manifests/${ARCH}-musl-latest" | sed -n 's/         "digest": "\(.*\)"/\1/p')"
	[ -z "$DIGEST" ] && return 2

	wget --header "Authorization: Bearer $TOKEN" -O - "https://ghcr.io/v2/${PKG_REPO}-${EXT}/blobs/$DIGEST" | tar xvz -C "${OUTPUT}" "${EXT}.vcz" "${EXT}.dep" "${EXT}.list" "${EXT}.sha256"
}


function dl_ext_with_deps() {
	local EXT="$1"

	dl_ext "${EXT}"

	while IFS= read -r DEP || [ -n "${DEP}" ]
	do
		dl_ext_with_deps "${DEP}"
	done < "${OUTPUT}/${EXT}.dep"
}


dl_ext_with_deps "${EXT}"
