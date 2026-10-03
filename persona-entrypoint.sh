#!/usr/bin/env bash
# persona-entrypoint.sh
#
# Stub for the persona runtime. The point of this script today is to
# prove the host bind-mounts work:
#   - `nak` should be callable on PATH (mounted from /usr/local/bin/nak)
#   - /etc/nostr/dot should be writable (mounted from the host)
#
# Replace the body with the real persona logic when we wire it.

set -euo pipefail

NAK=/usr/local/bin/nak
DOT_DIR=/etc/nostr/dot

check_nak() {
  if [[ -x "${NAK}" ]]; then
    echo "[persona] nak present: $(${NAK} --version 2>&1 | head -n1)"
  else
    echo "[persona] WARN: ${NAK} not found — host bind-mount missing?" >&2
    return 1
  fi
}

ensure_dot_writable() {
  if [[ -w "${DOT_DIR}" ]]; then
    echo "[persona] ${DOT_DIR} writable"
  else
    echo "[persona] WARN: ${DOT_DIR} not writable — host bind-mount missing?" >&2
    return 1
  fi
}

case "${1:-}" in
  --check-nak)
    check_nak
    ensure_dot_writable
    ;;
  *)
    check_nak || true
    ensure_dot_writable || true
    echo "[persona] stub entrypoint — replace with real persona runtime"
    # Sleep so the container stays up for inspection during dev.
    exec sleep infinity
    ;;
esac