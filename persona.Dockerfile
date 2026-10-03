# persona.Dockerfile
#
# Minimal persona image: bare runtime + nothing else for signing.
# `nak` is provided by the host bind-mount at /usr/local/bin/nak:ro,
# so we deliberately do NOT install it here.
#
# DoT state is provided by the host bind-mount at /etc/nostr/dot:rw.

FROM debian:bookworm-slim

# Minimal runtime deps. `ca-certificates` is here because DoT resolvers
# need a sane CA bundle; `tini` gives us clean signal handling.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        tini \
 && rm -rf /var/lib/apt/lists/*

# Stub entrypoint. Replace with the real persona runtime when we wire it.
# The important bit for now: `nak` is callable on PATH because the host
# mount lands it at /usr/local/bin/nak (same path inside the container).
COPY persona-entrypoint.sh /usr/local/bin/persona-entrypoint.sh
RUN chmod 0755 /usr/local/bin/persona-entrypoint.sh

# DoT config directory the persona can write into. The host bind-mount
# overlays this with /etc/nostr/dot, but we keep a sane default here so
# the image works on its own for local dev.
RUN mkdir -p /etc/nostr/dot

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/persona-entrypoint.sh"]
CMD ["--check-nak"]

# Sanity check (does not require the host mount to succeed when running
# outside compose — `nak` will simply be missing and the entrypoint will
# log a warning and exit non-zero so it's obvious).
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD /usr/local/bin/persona-entrypoint.sh --check-nak || exit 1