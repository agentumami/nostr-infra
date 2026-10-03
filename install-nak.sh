#!/usr/bin/env bash
# install-nak.sh
# Install `nak` (nostr army knife) once on the host at /usr/local/bin/nak.
# Personas will mount this binary in read-only.
#
# Source: https://github.com/fiatjaf/nak
#
# Usage: sudo ./install-nak.sh
set -euo pipefail

VERSION="${NAK_VERSION:-latest}"
DEST="${NAK_DEST:-/usr/local/bin/nak}"

if [[ -t 1 ]]; then
  echo ">> installing nak to ${DEST} (version: ${VERSION})"
fi

# Pick the right asset for the host arch.
case "$(uname -m)" in
  x86_64)  asset="nak-linux-amd64"  ;;
  aarch64) asset="nak-linux-arm64"  ;;
  armv7l)  asset="nak-linux-arm-7"  ;;
  *)
    echo "unsupported arch: $(uname -m)" >&2
    exit 1
    ;;
esac

if [[ "${VERSION}" == "latest" ]]; then
  url="https://github.com/fiatjaf/nak/releases/latest/download/${asset}"
else
  url="https://github.com/fiatjaf/nak/releases/download/${VERSION}/${asset}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

curl -fsSL -o "${tmp}/${asset}" "${url}"
chmod 0755 "${tmp}/${asset}"

# Install (or upgrade).
if [[ -e "${DEST}" ]]; then
  echo ">> ${DEST} exists, replacing"
fi
install -m 0755 "${tmp}/${asset}" "${DEST}"

echo ">> installed:"
"${DEST}" --version || true