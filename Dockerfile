FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends 7zip \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
