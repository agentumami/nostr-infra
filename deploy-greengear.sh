#!/usr/bin/env bash
# deploy-greengear.sh
# One-shot deploy of the nostr-infra mock-up onto greengear-ms-7a38.
#
# Steps:
#   1. Clone (or pull) the repo so the local install script is fresh.
#   2. Run install-nak.sh from the cloned repo (single source of truth
#      for the install path / asset name).
#   3. Create /etc/nostr/<persona>/ state dirs.
#   4. `docker compose up -d --build`.
#   5. Show status + last logs for each persona.
#
# Run from any host with SSH access to greengear-ms-7a38.

REMOTE="${REMOTE:-greengear-ms-7a38}"
REPO_URL="${REPO_URL:-https://github.com/agentumami/nostr-infra}"
REPO_DIR="${REPO_DIR:-/home/theadmin/nostr-infra}"

set -euo pipefail

ssh "${REMOTE}" bash -s -- "${REPO_URL}" "${REPO_DIR}" <<'REMOTE_SCRIPT'
set -euo pipefail

REPO_URL="$1"
REPO_DIR="$2"

echo "==== 1/5  clone or pull repo ===="
if [[ -d "${REPO_DIR}/.git" ]]; then
  (cd "${REPO_DIR}" && git pull --ff-only)
else
  git clone "${REPO_URL}" "${REPO_DIR}"
fi

echo "==== 2/5  install nak (via repo script) ===="
sudo "${REPO_DIR}/install-nak.sh"

echo "==== 3/5  persona state dirs ===="
sudo mkdir -p /etc/nostr/veyra /etc/nostr/strix /etc/nostr/kestrel
sudo chown -R "${USER}": /etc/nostr

echo "==== 4/5  docker compose up ===="
(cd "${REPO_DIR}" && docker compose up -d --build)

echo "==== 5/5  status + logs ===="
(cd "${REPO_DIR}" && docker compose ps)
echo
echo "--- veyra (last 40 lines) ---"
docker logs --tail=40 veyra 2>&1 || true
echo
echo "--- strix (last 40 lines) ---"
docker logs --tail=40 strix 2>&1 || true
echo
echo "--- kestrel (last 40 lines) ---"
docker logs --tail=40 kestrel 2>&1 || true
REMOTE_SCRIPT

echo
echo "==== done ===="