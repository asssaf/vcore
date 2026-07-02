# syntax=docker/dockerfile:1.3-labs
FROM ghcr.io/void-linux/void-musl-busybox:20260601r1 AS build

RUN xbps-install -Syu xbps

RUN mkdir -p /mnt/var/db/xbps/keys
RUN cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

ARG ARCH=aarch64
ARG REPO=https://repo-default.voidlinux.org/current/${ARCH}

RUN XBPS_ARCH=${ARCH}-musl xbps-install -Sy -r /mnt -R "$REPO" busybox-huge base-files
RUN for A in $(busybox --list); do busybox ln -s busybox /mnt/usr/bin/$A; done 


FROM build AS build-packages

RUN xbps-install -y bash shadow git base-devel coreutils util-linux

RUN git clone --depth=1 https://github.com/void-linux/void-packages.git /root/void-packages

WORKDIR /root/void-packages
RUN echo -e 'XBPS_CHROOT_CMD=ethereal\nXBPS_ALLOW_CHROOT_BREAKOUT=yes' > etc/conf
RUN ln -s / masterdir
RUN ./xbps-src -a aarch64-musl binary-bootstrap

RUN ./xbps-src -a aarch64-musl fetch busybox-huge
RUN ./xbps-src -a aarch64-musl extract busybox-huge
RUN ./xbps-src -a aarch64-musl patch busybox-huge
RUN ./xbps-src -a aarch64-musl configure busybox-huge
RUN ./xbps-src -a aarch64-musl build busybox-huge
RUN ./xbps-src -a aarch64-musl install busybox-huge
RUN ./xbps-src -a aarch64-musl pkg busybox-huge


FROM build AS build-initramfs

RUN cd /mnt && find . -print0 | cpio --null -ov -H newc | gzip > /initramfs.cpio.gz 


FROM scratch AS export

COPY --from=build /mnt /


FROM scratch AS export-initramf

COPY --from=build-initramfs /initramfs.cpio.gz /

