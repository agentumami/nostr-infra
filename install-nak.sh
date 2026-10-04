#!/usr/bin/env bash
# install-nak.sh
# Install `nak` (nostr army knife) once on the host at /usr/local/bin/nak.
# Personas will mount this binary in read-only.
#
# Source: https://github.com/fiatjaf/nak
#
# Usage: sudo ./install-nak.sh
#
# Behavior:
#   - NAK_VERSION (env, default: latest) selects which release to fetch.
#   - Asset name is discovered via the GitHub release API because the
#     upstream asset naming changed from `nak-<arch>` to `nak-vX.Y.Z-<arch>`
#     and we want to work against both shapes.
set -euo pipefail

VERSION="${NAK_VERSION:-latest}"
DEST="${NAK_DEST:-/usr/local/bin/nak}"

if [[ -t 1 ]]; then
  echo ">> installing nak to ${DEST} (version: ${VERSION})"
fi

case "$(uname -m)" in
  x86_64)  arch="amd64"  ;;
  aarch64) arch="arm64"  ;;
  armv7l)  arch="arm-7"  ;;
  *)
    echo "unsupported arch: $(uname -m)" >&2
    exit 1
    ;;
esac

# Resolve tag and asset name from the GitHub API.
api_url() {
  if [[ "${VERSION}" == "latest" ]]; then
    echo "https://api.github.com/repos/fiatjaf/nak/releases/latest"
  else
    echo "https://api.github.com/repos/fiatjaf/nak/releases/tags/${VERSION}"
  fi
}

release_json="$(curl -fsSL "$(api_url)")"
tag="$(printf '%s' "${release_json}" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
if [[ -z "${tag}" ]]; then
  echo "could not determine tag from release API response" >&2
  exit 1
fi

# Try the modern shape first (`nak-vX.Y.Z-<arch>`), then fall back to
# the older bare-name shape (`nak-<arch>`) in case an older release is
# pinned via NAK_VERSION.
asset_candidates=(
  "nak-${tag}-linux-${arch}"
  "nak-linux-${arch}"
)

asset=""
for cand in "${asset_candidates[@]}"; do
  if printf '%s' "${release_json}" | grep -q "\"name\": *\"${cand}\""; then
    asset="${cand}"
    break
  fi
done

if [[ -z "${asset}" ]]; then
  echo "could not find a linux/${arch} asset in release ${tag}; tried:" >&2
  printf '  %s\n' "${asset_candidates[@]}" >&2
  exit 1
fi

url="https://github.com/fiatjaf/nak/releases/download/${tag}/${asset}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

curl -fsSL -o "${tmp}/${asset}" "${url}"
chmod 0755 "${tmp}/${asset}"

if [[ -e "${DEST}" ]]; then
  echo ">> ${DEST} exists, replacing"
fi
install -m 0755 "${tmp}/${asset}" "${DEST}"

echo ">> installed ${tag}:"
"${DEST}" --version || true