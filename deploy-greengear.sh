#!/usr/bin/env bash
# deploy-greengear.sh
# One-shot deploy of the nostr-infra mock-up onto greengear-ms-7a38.
#
# Steps:
#   1. Install `nak` on the host (idempotent).
#   2. Create /etc/nostr/<persona>/ dirs for each persona.
#   3. Clone (or pull) the nostr-infra repo.
#   4. `docker compose up -d --build`.
#   5. Tail the persona logs long enough to confirm the MSISDN claim
#      events got published to the relay.
#
# Run from any host with SSH access to greengear-ms-7a38. The script
# SSHes in once and runs everything over that session.

REMOTE="${REMOTE:-greengear-ms-7a38}"
REPO_URL="${REPO_URL:-https://github.com/agentumami/nostr-infra}"
REPO_DIR="${REPO_DIR:-/home/theadmin/nostr-infra}"

set -euo pipefail

ssh "${REMOTE}" bash -s -- "${REPO_URL}" "${REPO_DIR}" <<'REMOTE_SCRIPT'
set -euo pipefail

REPO_URL="$1"
REPO_DIR="$2"

echo "==== 1/5  install nak ===="
if [[ -x /usr/local/bin/nak ]]; then
  echo "nak already present: $(/usr/local/bin/nak --version 2>&1 | head -n1)"
else
  curl -fsSL https://github.com/fiatjaf/nak/releases/latest/download/nak-linux-amd64 \
    -o /usr/local/bin/nak
  chmod 0755 /usr/local/bin/nak
  echo "installed: $(/usr/local/bin/nak --version 2>&1 | head -n1)"
fi

echo "==== 2/5  persona state dirs ===="
sudo mkdir -p /etc/nostr/veyra /etc/nostr/strix /etc/nostr/kestrel
sudo chown -R "${USER}": /etc/nostr

echo "==== 3/5  clone or pull repo ===="
if [[ -d "${REPO_DIR}/.git" ]]; then
  (cd "${REPO_DIR}" && git pull --ff-only)
else
  git clone "${REPO_URL}" "${REPO_DIR}"
fi

echo "==== 4/5  docker compose up ===="
(cd "${REPO_DIR}" && docker compose up -d --build)

echo "==== 5/5  status ===="
(cd "${REPO_DIR}" && docker compose ps)

echo
echo "--- veyra (first 30 lines) ---"
docker logs --tail=30 veyra 2>&1 || true
echo
echo "--- strix (first 30 lines) ---"
docker logs --tail=30 strix 2>&1 || true
echo
echo "--- kestrel (first 30 lines) ---"
docker logs --tail=30 kestrel 2>&1 || true
REMOTE_SCRIPT

echo
echo "==== done ===="