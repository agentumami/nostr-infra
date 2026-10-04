#!/usr/bin/env bash
# veyra-entrypoint.sh
# Persona runtime for Veyra (+1 202-555-0147).
#
# Responsibilities at this stage of the mock-up:
#   1. Confirm `nak` is callable (host bind-mount landed).
#   2. On first boot, publish a self-signed Nostr event that binds
#      PERSONA_MSISDN to this persona's pubkey. This is the persona's
#      "Directory of Truth" claim: "I, pubkey X, am +1 202-555-0147."
#   3. Stay up so the persona can (later) sign outbound messages on
#      demand and verify inbound ones.
#
# Keypair lives in /etc/nostr/state/nsec — host bind-mounted rw so it
# persists across container restarts. Created on first boot if missing.

set -euo pipefail

NAK=/usr/local/bin/nak
RELAY="${RELAY_URL:-ws://strfry:7777}"
STATE_DIR=/etc/nostr/state
NSEC_FILE="${STATE_DIR}/nsec"
PUB_FILE="${STATE_DIR}/npub"

log() { echo "[${PERSONA_NAME:-persona}] $*"; }
die() { echo "[${PERSONA_NAME:-persona}] $*" >&2; exit 1; }

# --- 1. nak check ---
[[ -x "${NAK}" ]] || die "nak not executable at ${NAK} — host bind-mount missing?"
log "nak: $(${NAK} --version 2>&1 | head -n1)"

mkdir -p "${STATE_DIR}"

# --- 2. Keypair bootstrap (first boot only) ---
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

# --- 3. Publish the MSISDN<->pubkey claim event ---
# Shape: a kind:0 profile metadata event with the MSISDN surfaced in
# both `name` and `about`. Self-signed by the persona's own nsec. Anyone
# who trusts the persona's pubkey can verify this; nothing more is
# needed at this stage of the mock-up. Later: replace with a custom
# kind + signed-challenge variant when we add out-of-band verification.
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
    # Retry briefly so we don't race strfry coming up.
    for _ in 1 2 3 4 5; do
      if publish_claim; then break; fi
      sleep 2
    done
    ;;
  --check)
    log "ok — nsec=$([ -s "${NSEC_FILE}" ] && echo present || echo missing), npub=${NPUB}"
    ;;
  *)
    # Default: publish the claim once, then idle so the container stays
    # up for inspection and (later) ad-hoc verification commands.
    for _ in 1 2 3 4 5; do
      if publish_claim; then break; fi
      sleep 2
    done
    exec sleep infinity
    ;;
esac