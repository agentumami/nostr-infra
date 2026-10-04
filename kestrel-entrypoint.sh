#!/usr/bin/env bash
# kestrel-entrypoint.sh — see veyra-entrypoint.sh for the contract.

set -euo pipefail

NAK=/usr/local/bin/nak
RELAY="${RELAY_URL:-ws://strfry:7777}"
STATE_DIR=/etc/nostr/state
NSEC_FILE="${STATE_DIR}/nsec"
PUB_FILE="${STATE_DIR}/npub"

log() { echo "[${PERSONA_NAME:-persona}] $*"; }
die() { echo "[${PERSONA_NAME:-persona}] $*" >&2; exit 1; }

[[ -x "${NAK}" ]] || die "nak not executable at ${NAK} — host bind-mount missing?"
log "nak: $(${NAK} --version 2>&1 | head -n1)"

mkdir -p "${STATE_DIR}"
if [[ ! -s "${NSEC_FILE}" ]]; then
  log "no nsec in ${STATE_DIR}, generating new keypair"
  "${NAK}" key generate > "${NSEC_FILE}"
  chmod 0600 "${NSEC_FILE}"
fi
NSEC="$(cat "${NSEC_FILE}")"
NPUB="$("${NAK}" key public "${NSEC}" 2>/dev/null || true)"
echo "${NPUB}" > "${PUB_FILE}"
chmod 0644 "${PUB_FILE}"

log "pubkey: ${NPUB}"
log "msisdn: ${PERSONA_MSISDN:-<unset>}"

publish_claim() {
  local content
  content="$(printf '{"name":"%s","about":"MSISDN: %s"}' \
    "${PERSONA_NAME}" "${PERSONA_MSISDN}")"
  "${NAK}" event \
    --sec "${NSEC}" \
    --kind 0 \
    --content "${content}" \
    --tag "t" "msisdn" \
    --tag "tel" "${PERSONA_MSISDN}" \
    --relay "${RELAY}" || {
      log "WARN: claim publish failed (relay up yet?)"
      return 1
    }
  log "claim published to ${RELAY}"
}

case "${1:-}" in
  --publish-claim)
    for _ in 1 2 3 4 5; do
      if publish_claim; then break; fi
      sleep 2
    done
    ;;
  --check)
    log "ok — nsec=$([ -s "${NSEC_FILE}" ] && echo present || echo missing), npub=${NPUB}"
    ;;
  *)
    for _ in 1 2 3 4 5; do
      if publish_claim; then break; fi
      sleep 2
    done
    exec sleep infinity
    ;;
esac