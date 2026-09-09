# syntax=docker/dockerfile:1
ARG ARCH
ARG XBPS_ARCH=${ARCH}-musl
ARG REPO="https://repo-default.voidlinux.org/current/${ARCH}"
ARG REPO="${REPO/x86_64/musl}"
ARG REPO="${REPO/armv6l/musl}"
ARG BUSYBOX_BINPKGS=ghcr.io/asssaf/void-packages-busybox-custom:${XBPS_ARCH}-latest


# Base stage to use for cleanup and later stages
# By default the install stage is used which includes some packages, plus the custom built busybox
# This can be customized to create additional initramfs archives with optional packages for testing
# by setting INSTALL_STAGE=install-packages and INSTALL_PACKAGES="base-files <some-pkg> ..."
ARG INSTALL_STAGE=install

# Stage to use for sourcing a package
ARG PACKAGE_SOURCE_STAGE=download-package


FROM ghcr.io/void-linux/void-musl-busybox:20260601r1 AS base

RUN xbps-install -Syu xbps squashfs-tools zstd

RUN mkdir -p /mnt/var/db/xbps/keys
RUN cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/


FROM base AS install-packages-base

ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}
RUN xbps-install -Sy -r "/mnt" -R "$REPO"


FROM install-packages-base AS install-packages

RUN mkdir -p /mnt/etc/xbps.d
RUN echo 'noextract=/usr/share/man*' >> /mnt/etc/xbps.d/noextract.conf
RUN echo 'noextract=/usr/share/doc*' >> /mnt/etc/xbps.d/noextract.conf
RUN echo 'noextract=/usr/share/info*' >> /mnt/etc/xbps.d/noextract.conf

ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}
ARG INSTALL_PACKAGES="musl base-files xbps-triggers"
RUN xbps-install -y -r "/mnt" -R "$REPO" $INSTALL_PACKAGES

RUN wget -O - https://github.com/ewhauser/shuck/releases/download/v0.1.1/shuck-cli-x86_64-unknown-linux-musl.tar.xz | xzcat | tar xv -C /tmp/

ARG ROOTFS=rootfs
COPY $ROOTFS /tmp/rootfs
RUN /tmp/shuck-cli-x86_64-unknown-linux-musl/shuck check /tmp/rootfs
COPY $ROOTFS /mnt


FROM install-packages-base AS create-package-list

ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}
ARG INSTALL_PACKAGES="musl base-files"

RUN xbps-install -r "/mnt" -R "$REPO" -n $INSTALL_PACKAGES | sed 's|^\(\([^ ]*\)-.*\) install \([^ ]*\) \([^ ]*\).*$|\2 \4/\1.\3.xbps|' > /pkg.list



FROM scratch AS export-package-list

COPY --from=create-package-list /pkg.list /


FROM install-packages-base AS download-package

ARG PKG
ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}

RUN xbps-install -y -r "/mnt" -R "$REPO" --download-only $PKG
RUN mv /mnt/var/cache/xbps/${PKG}*.xbps /


FROM ${PACKAGE_SOURCE_STAGE} AS package-source


FROM install-packages-base AS convert-package

ARG PKG
ARG VCE_INSTALLED="/usr/local/vce.installed/${PKG}"

COPY --from=package-source / /pkg
RUN mkdir -p /mnt/pkg
RUN zstdcat /pkg/${PKG}*.xbps | tar xv -C /mnt/pkg

RUN mkdir -p "/mnt/pkg/${VCE_INSTALLED}"
RUN if [ -e "/mnt/pkg/INSTALL" ]; then mv "/mnt/pkg/INSTALL" "/mnt/pkg/${VCE_INSTALLED}/"; fi
RUN if [ -e "/mnt/pkg/REMOVE" ]; then mv "/mnt/pkg/REMOVE" "/mnt/pkg/${VCE_INSTALLED}/"; fi

COPY excludes /tmp/

RUN mksquashfs /mnt/pkg "/${PKG}.vcz" -ef /tmp/excludes
RUN unsquashfs -l "/${PKG}.vcz" | sed 's|^squashfs-root||;/^$/d' > "/${PKG}.list"
RUN xbps-rindex -a /pkg/*.xbps
RUN xbps-query -R --repository /pkg -x "${PKG}" | sed 's/\(.*\)[-><].*$/\1/' | sed -n '/musl/!p' | sed -n '/^$/!p' > "/${PKG}.dep"
RUN cd / && sha256sum ${PKG}.vcz > ${PKG}.sha256


FROM scratch AS export-package

COPY --from=convert-package /*.vcz /
COPY --from=convert-package /*.dep /
COPY --from=convert-package /*.list /
COPY --from=convert-package /*.sha256 /


FROM scratch AS export-packages

COPY --from=install-packages /pkg/* /


FROM ${BUSYBOX_BINPKGS} AS busybox-binpkgs


FROM install-packages AS install-busybox

COPY --from=busybox-binpkgs / /binpkgs
ARG XBPS_ARCH
ENV XBPS_ARCH=${XBPS_ARCH}

RUN xbps-rindex -a /binpkgs/*.xbps
RUN xbps-install -y -r /mnt -R /binpkgs busybox-custom
RUN chroot /mnt /usr/bin/busybox --install -s
RUN chmod u+s /mnt/usr/bin/busybox


FROM install-busybox AS install
FROM ${INSTALL_STAGE} AS install-stage


FROM install-stage AS cleanup

RUN rm -rf /mnt/var/db/xbps
RUN rm -rf /mnt/var/cache/xbps
RUN rm -rf /mnt/boot
RUN rm -rf /mnt/etc/xbps.d


FROM cleanup AS build-initramfs

RUN cd /mnt && find . -print0 | cpio --null -ov -H newc | gzip > /initramfs.cpio.gz 


FROM scratch AS export

COPY --from=cleanup /mnt /


FROM scratch AS export-initramfs

COPY --from=build-initramfs /initramfs.cpio.gz /


FROM install-packages-base AS install-extensions

ARG ARCH
ARG PKG_REPO
ARG INSTALL_PACKAGES

COPY dl-ext.sh /
RUN mkdir -p /vce/optional
RUN for EXT in $INSTALL_PACKAGES; \
	do \
		EXT=$EXT OUTPUT=/vce/optional /dl-ext.sh; \
		echo "$EXT" >> /vce/onboot.lst; \
	done


FROM scratch AS export-extensions

COPY --from=install-extensions /vce /vce


FROM install-packages-base AS build-images

ARG PART_SIZE_MB=200
ARG DISK_SIZE_MB=201

RUN XBPS_ARCH="" xbps-install -y mtools parted 7zip

RUN truncate -s ${PART_SIZE_MB}M firmware-with-vce.img
RUN mformat -i firmware-with-vce.img ::

COPY --from=install-extensions /vce /vce
RUN mcopy -spQnmvi firmware-with-vce.img vce ::/
#RUN mcopy -spQnmovi firmware-with-vce.img /config.txt /cmdline.txt ::/ 2>&1
RUN mlabel -ni firmware-with-vce.img ::RECOVERY

RUN truncate -s ${DISK_SIZE_MB}M firmware-with-vce-disk.img
RUN parted -s firmware-with-vce-disk.img mklabel msdos mkpart primary fat16 2048s 100%
RUN dd if="firmware-with-vce.img" of=firmware-with-vce-disk.img bs=512 seek=2048


FROM scratch AS export-firmware-with-vce

COPY --from=build-images /firmware-with-vce.img /


FROM scratch AS export-firmware-with-vce-disk

COPY --from=build-images /firmware-with-vce-disk.img /
