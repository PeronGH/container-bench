FROM gcc:15.2-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        7zip \
        bc \
        bison \
        flex \
        libelf-dev \
    && rm -rf /var/lib/apt/lists/*

ARG KERNEL_VERSION=6.18.35

RUN curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
        | tar -xJ -C /usr/src \
    && ln -s "linux-${KERNEL_VERSION}" /usr/src/linux

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
