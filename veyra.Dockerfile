# veyra.Dockerfile
# Per-persona image. Persona name baked at build time so the entrypoint
# knows which MSISDN it's binding to which keypair.
#
# This Dockerfile is a thin wrapper: the bulk of the runtime lives in
# `persona.Dockerfile` (shared base). Per-persona files (keypair,
# MSISDN) are bind-mounted in from the host at the paths below.

FROM persona-base

# Persona identity (baked at build time, read-only at runtime via env).
ARG PERSONA_NAME=veyra
ARG PERSONA_MSISDN=+12025550147
ENV PERSONA_NAME=${PERSONA_NAME}
ENV PERSONA_MSISDN=${PERSONA_MSISDN}

# Per-persona entrypoint. Replaces the generic stub — this one knows how
# to publish the MSISDN<->pubkey claim and (later) verify peers.
COPY veyra-entrypoint.sh /usr/local/bin/persona-entrypoint.sh
RUN chmod 0755 /usr/local/bin/persona-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/persona-entrypoint.sh"]
CMD ["--publish-claim"]