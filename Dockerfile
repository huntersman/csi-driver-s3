FROM alpine:3.15 AS s3fs-builder
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.15/main/ > /etc/apk/repositories

ARG S3FS_VERSION=v1.90

RUN apk --no-cache add \
        ca-certificates \
        build-base \
        git \
        alpine-sdk \
        libcurl \
        automake \
        autoconf \
        libxml2-dev \
        fuse-dev \
        curl-dev \
 && git clone https://hub.fastgit.xyz/s3fs-fuse/s3fs-fuse.git \
 && cd s3fs-fuse \
 && git checkout tags/${S3FS_VERSION} \
 && ./autogen.sh \
 &&./configure --prefix=/usr \
 && make -j \
 && make install \
 && strip /usr/bin/s3fs

FROM golang:1.17-alpine as builder
RUN apk add git make binutils
COPY / /work
WORKDIR /work
RUN make

FROM alpine:3.15
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.15/main/ > /etc/apk/repositories
RUN apk --no-cache add \
    ca-certificates \
    fuse \
    libxml2 \
    libcurl \
    libgcc \
    libstdc++ \
    util-linux
COPY --from=s3fs-builder /usr/bin/s3fs /usr/bin/s3fs
RUN /usr/bin/s3fs --version
COPY --from=builder /work/bin/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
