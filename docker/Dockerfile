# syntax=docker/dockerfile:1
ARG ARCH
ARG XBPS_ARCH=${ARCH}-musl
ARG REPO="https://repo-default.voidlinux.org/current/${ARCH}"
ARG REPO="${REPO/x86_64/musl}"


FROM ghcr.io/void-linux/void-musl-busybox:20260601r1 AS build

RUN xbps-install -Syu xbps

RUN mkdir -p /mnt/var/db/xbps/keys
RUN cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/


FROM build AS build-packages

RUN xbps-install -Sy bash shadow git base-devel coreutils util-linux

RUN git clone --depth=1 https://github.com/void-linux/void-packages.git /root/void-packages

WORKDIR /root/void-packages
RUN echo -e "XBPS_CHROOT_CMD=ethereal\nXBPS_ALLOW_CHROOT_BREAKOUT=yes" > etc/conf
RUN ln -s / masterdir
ARG XBPS_ARCH
ARG XBPS_SRC_ARCH="-a ${XBPS_ARCH}"
ARG XBPS_SRC_ARCH="${XBPS_SRC_ARCH/-a x86_64-musl/}"
RUN ./xbps-src ${XBPS_SRC_ARCH} binary-bootstrap


FROM build-packages AS build-busybox

COPY files srcpkgs/busybox/files
RUN cd srcpkgs/busybox && patch template files/template.patch
RUN ln -s busybox srcpkgs/busybox-custom
ARG PKG=busybox-custom
ARG XBPS_SRC_ARCH
RUN ./xbps-src $XBPS_SRC_ARCH fetch $PKG
RUN ./xbps-src $XBPS_SRC_ARCH extract $PKG
RUN ./xbps-src $XBPS_SRC_ARCH patch $PKG
RUN ./xbps-src $XBPS_SRC_ARCH configure $PKG
RUN ./xbps-src $XBPS_SRC_ARCH build $PKG
RUN ./xbps-src $XBPS_SRC_ARCH install $PKG
RUN ./xbps-src $XBPS_SRC_ARCH pkg $PKG


FROM build-packages AS install-packages

ARG XBPS_ARCH
ARG REPO
ENV XBPS_ARCH=${XBPS_ARCH}
RUN xbps-install -S -y -r /mnt -R "$REPO" musl base-files


FROM install-packages AS install-busybox

COPY --from=build-busybox /root/void-packages/hostdir /hostdir
ARG XBPS_ARCH
ENV XBPS_ARCH=${XBPS_ARCH}
RUN xbps-rindex -a /hostdir/binpkgs/*.xbps
RUN xbps-install -y -r /mnt -R /hostdir/binpkgs busybox-custom
RUN chroot /mnt /usr/bin/busybox --install -s


FROM install-busybox AS install

COPY init /mnt/


FROM install AS build-initramfs

RUN cd /mnt && find . -print0 | cpio --null -ov -H newc | gzip > /initramfs.cpio.gz 


FROM scratch AS export

COPY --from=install /mnt /


FROM scratch AS export-initramfs

COPY --from=build-initramfs /initramfs.cpio.gz /

