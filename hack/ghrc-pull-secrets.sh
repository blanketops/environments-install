#!/usr/bin/env bash
# hack/ghcr-pull-secret.sh
#
# LOCAL TEST SCAFFOLDING — creates the ghcr-pull imagePullSecret and binds
# it to the controller-manager ServiceAccount so the manager image can be
# pulled while the GHCR package is private.
#
# NOT part of the shipped installer. Delete this script (and the secret)
# when the package goes public.
#
# Token resolution order:
#   1. GITHUB_TOKEN in ./.env (never committed — ensure .env is gitignored)
#   2. GITHUB_TOKEN already exported in the environment
#   3. gh CLI keyring token (GITHUB_TOKEN env var deliberately ignored —
#      it has a history of being stale on this machine)
#
# Usage:
#   ./hack/ghcr-pull-secret.sh            # default namespace/SA
#   NAMESPACE=foo SA=bar ./hack/ghcr-pull-secret.sh

set -euo pipefail

NAMESPACE="${NAMESPACE:-blanketops-environments}"
SA="${SA:-blanketops-environments-controller-manager}"
SECRET_NAME="${SECRET_NAME:-ghcr-pull}"
GHCR_USER="${GHCR_USER:-ntlaletsi70}"
ENV_FILE="$(dirname "$0")/../.env"

# ── Resolve token ─────────────────────────────────────────────────────────
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "${GITHUB_TOKEN}" ] && [ -f "${ENV_FILE}" ]; then
  # shellcheck disable=SC1090
  set -a; source "${ENV_FILE}"; set +a
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "==> GITHUB_TOKEN not set and not in .env — trying gh CLI keyring"
  GITHUB_TOKEN="$(env -u GITHUB_TOKEN gh auth token 2>/dev/null || true)"
fi

if [ -z "${GITHUB_TOKEN}" ]; then
  cat >&2 <<'EOF'
ERROR: no GitHub token found.

Provide one via any of:
  1. echo 'GITHUB_TOKEN=ghp_...' > .env          (gitignored)
  2. export GITHUB_TOKEN=ghp_...
  3. gh auth login                          (keyring)

The token needs the read:packages scope for GHCR pulls.
EOF
  exit 1
fi

# ── Sanity: token can actually pull from GHCR ─────────────────────────────
echo "==> Verifying token has read:packages against ghcr.io"
if ! curl -sf -u "${GHCR_USER}:${GITHUB_TOKEN}" \
    "https://ghcr.io/token?scope=repository:${GHCR_USER}/blanketops-environments-controller:pull&service=ghcr.io" \
    >/dev/null; then
  echo "ERROR: token rejected by ghcr.io — check read:packages scope" >&2
  exit 1
fi

# ── Create/refresh secret ─────────────────────────────────────────────────
echo "==> Creating secret ${SECRET_NAME} in ${NAMESPACE}"
kubectl -n "${NAMESPACE}" create secret docker-registry "${SECRET_NAME}" \
  --docker-server=ghcr.io \
  --docker-username="${GHCR_USER}" \
  --docker-password="${GITHUB_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── Bind to ServiceAccount ────────────────────────────────────────────────
echo "==> Binding ${SECRET_NAME} to ServiceAccount ${SA}"
kubectl -n "${NAMESPACE}" patch serviceaccount "${SA}" \
  -p "{\"imagePullSecrets\":[{\"name\":\"${SECRET_NAME}\"}]}"

# ── Bounce the manager so a fresh pod picks up the SA change ──────────────
echo "==> Restarting controller-manager pods"
kubectl -n "${NAMESPACE}" delete pod -l control-plane=controller-manager --ignore-not-found

echo "✔ done — watch with: kubectl -n ${NAMESPACE} get pods -w"