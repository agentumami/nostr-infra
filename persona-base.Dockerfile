# persona-base.Dockerfile
# Shared persona base image. Per-persona Dockerfiles (veyra.Dockerfile
# etc.) build FROM this.
#
# Provides:
#   - debian-slim runtime + ca-certificates + tini
#   - default /etc/nostr/<persona>/ layout for persona-local state
#
# Does NOT install `nak` — that's mounted read-only from the host at
# /usr/local/bin/nak, the same path it lives at on the host.

FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        tini \
 && rm -rf /var/lib/apt/lists/*

# Persona-local state lives here. The host bind-mount overlays this with
# the per-persona dir under /etc/nostr/<persona>/ so state survives
# container restarts and image rebuilds.
RUN mkdir -p /etc/nostr/state

# `nak` will land at /usr/local/bin/nak via the host bind-mount at
# container run time. No install step here.

# Image name when built standalone:
#   docker build -t persona-base -f persona-base.Dockerfile .
#
# Per-persona images depend on this being available; compose handles it
# via the `image:` declaration in the persona service.