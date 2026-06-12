FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG KERNEL_VERSION=6.18.35

RUN curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
        | tar -xJ -C /usr/src \
    && ln -s "linux-${KERNEL_VERSION}" /usr/src/linux

ENV BENCH_APT_PACKAGES="7zip bc bison flex gcc libc6-dev libelf-dev make"

# docker-clean deletes downloaded debs after every apt run; the apt step needs them
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends --download-only $BENCH_APT_PACKAGES

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
