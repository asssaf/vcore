# syntax=docker/dockerfile:1
ARG ARCH
ARG XBPS_ARCH=${ARCH}-musl
ARG REPO="https://repo-default.voidlinux.org/current/${ARCH}"
ARG REPO="${REPO/x86_64/musl}"
ARG REPO="${REPO/armv6l/musl}"

# By default busybox is built from source during the main build
# To skip building busybox from source, this can be set to a previously built binpgk
# e.g. BUSYBOX_BINPKGS=ghcr.io/asssaf/vcore-busybox-binpkgs:${ARCH}
ARG BUSYBOX_BINPKGS=export-binpkgs

# Base stage to use for cleanup and later stages
# By default the install stage is used which includes some packages, plus the custom built busybox
# This can be customized to create additional initramfs archives with optional packages for testing
# by setting INSTALL_STAGE=install-packages and INSTALL_PACKAGES="base-files <some-pkg> ..."
ARG INSTALL_STAGE=install

# Stage to use for sourcing a package
ARG PACKAGE_SOURCE_STAGE=download-package


FROM ghcr.io/void-linux/void-musl-busybox:20260601r1 AS base

RUN xbps-install -Syu xbps

RUN mkdir -p /mnt/var/db/xbps/keys
RUN cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/


FROM base AS install-packages-base

ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}
RUN xbps-install -Sy -r "/mnt" -R "$REPO"


FROM install-packages-base AS build-packages-base

RUN XBPS_ARCH="" xbps-install -Sy bash shadow git base-devel coreutils util-linux squashfs-tools zstd

RUN mkdir /root/void-packages
WORKDIR /root/void-packages

ARG VOID_PACKAGES_URL=https://github.com/asssaf/void-packages/archive/refs/heads/master.tar.gz
RUN wget -O - "${VOID_PACKAGES_URL}" | tar xvz --strip-components=1

RUN echo -e "XBPS_CHROOT_CMD=ethereal\nXBPS_ALLOW_CHROOT_BREAKOUT=yes" > etc/conf
RUN ln -s / masterdir
ARG XBPS_ARCH
ARG XBPS_SRC_ARCH="-a ${XBPS_ARCH}"
ARG XBPS_SRC_ARCH="${XBPS_SRC_ARCH/-a x86_64-musl/}"
RUN ./xbps-src ${XBPS_SRC_ARCH} binary-bootstrap


FROM build-packages-base AS build-package

ARG PKG=busybox-custom
ARG XBPS_SRC_ARCH
RUN ./xbps-src $XBPS_SRC_ARCH fetch $PKG
RUN ./xbps-src $XBPS_SRC_ARCH extract $PKG
RUN ./xbps-src $XBPS_SRC_ARCH patch $PKG
RUN ./xbps-src $XBPS_SRC_ARCH configure $PKG
RUN ./xbps-src $XBPS_SRC_ARCH build $PKG
RUN ./xbps-src $XBPS_SRC_ARCH install $PKG
RUN ./xbps-src $XBPS_SRC_ARCH pkg $PKG


FROM scratch AS export-binpkgs

COPY --from=build-package /root/void-packages/hostdir/binpkgs /binpkgs


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


FROM build-packages-base AS download-package

ARG PKG
ARG PKG_URL

RUN mkdir -p /pkg
RUN wget -O /pkg/hostpkg.xbps "${PKG_URL}"


FROM build-packages-base AS copy-package

ARG PKG
ARG HOST_PKG

RUN mkdir -p /pkg
COPY ${HOST_PKG} /pkg/hostpkg.xbps


FROM ${PACKAGE_SOURCE_STAGE} AS package-source


FROM build-packages-base AS convert-package

ARG PKG
ARG VCE_INSTALLED="/usr/local/vce.installed/${PKG}"

COPY --from=package-source /pkg /pkg
RUN mkdir -p /mnt/pkg
RUN zstdcat /pkg/hostpkg.xbps | tar xv -C /mnt/pkg

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

COPY --from=busybox-binpkgs /binpkgs /binpkgs
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


FROM cleanup AS build-squashfs

ENV XBPS_ARCH=""
RUN xbps-install -Sy squashfs-tools
RUN mksquashfs /mnt /out.squashfs


FROM scratch AS export-squashfs

COPY --from=build-squashfs /out.squashfs /


FROM scratch AS export

COPY --from=cleanup /mnt /


FROM scratch AS export-initramfs

COPY --from=build-initramfs /initramfs.cpio.gz /
