FROM golang:1.26-trixie AS ycsb

RUN git init -q /src \
    && git -C /src fetch -q --depth 1 https://github.com/pingcap/go-ycsb f030f9942393a8febbf4365c2d582711723159f5 \
    && git -C /src checkout -q FETCH_HEAD \
    && go build -C /src -o /usr/local/bin/go-ycsb ./cmd/go-ycsb

FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        7zip \
        bc \
        bison \
        ca-certificates \
        curl \
        flex \
        gcc \
        libc6-dev \
        libcurl4t64 \
        libelf-dev \
        libssl3t64 \
        make \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG KERNEL_VERSION=6.18.35

RUN curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
        | tar -xJ -C /usr/src \
    && ln -s "linux-${KERNEL_VERSION}" /usr/src/linux

ARG MONGODB_VERSION=8.2.10
ARG TARGETARCH

RUN case "$TARGETARCH" in \
        amd64) arch=x86_64 ;; \
        arm64) arch=aarch64 ;; \
        *) echo "unsupported arch: $TARGETARCH" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://fastdl.mongodb.org/linux/mongodb-linux-${arch}-ubuntu2404-${MONGODB_VERSION}.tgz" \
        | tar -xz -C /usr/local/bin --strip-components=2 --wildcards '*/bin/mongod'

COPY --from=ycsb /usr/local/bin/go-ycsb /usr/local/bin/go-ycsb

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
