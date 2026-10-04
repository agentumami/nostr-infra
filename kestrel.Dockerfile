# kestrel.Dockerfile
FROM persona-base

ARG PERSONA_NAME=kestrel
ARG PERSONA_MSISDN=+12025550196
ENV PERSONA_NAME=${PERSONA_NAME}
ENV PERSONA_MSISDN=${PERSONA_MSISDN}

COPY kestrel-entrypoint.sh /usr/local/bin/persona-entrypoint.sh
RUN chmod 0755 /usr/local/bin/persona-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/persona-entrypoint.sh"]
CMD ["--publish-claim"]