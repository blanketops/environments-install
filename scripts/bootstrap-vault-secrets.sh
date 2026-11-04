#!/bin/bash
# ============================================================
# bootstrap-vault-secrets.sh
#
# Populates Vault with all /blanketops/* secrets.
# Designed for an in-cluster Vault instance.
# ============================================================

# Configuration
VAULT_ADDR="http://vault.vault.svc.cluster.local:8200"
VAULT_TOKEN="root" # Use a proper token in production

echo "Bootstrapping BlanketOps secrets in Vault"
echo "Vault Address: $VAULT_ADDR"
echo ""

# Helper function to write to Vault KV v2
write_vault_secret() {
  local path=$1
  local value=$2
  echo "Creating $path..."
  curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
       --request POST \
       --data "{\"data\": {\"value\": \"$value\"}}" \
       "$VAULT_ADDR/v1/secret/data/$path" > /dev/null
}

# ── Git SSH ──────────────────────────────────────────────────

write_vault_secret "blanketops/environments/git/ssh-privatekey" "$(cat ~/.ssh/id_ed25519)"
write_vault_secret "blanketops/environments/git/ssh-publickey" "$(cat ~/.ssh/id_ed25519.pub)"
write_vault_secret "blanketops/environments/git/known-hosts" "$(ssh-keyscan github.com 2>/dev/null)"

# ── Registry ─────────────────────────────────────────────────

DOCKER_AUTH=$(echo -n "<USERNAME>:<TOKEN>" | base64)
REGISTRY_CONFIG="{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$DOCKER_AUTH\"}}}"
write_vault_secret "blanketops/environments/registry/config" "$REGISTRY_CONFIG"

# ── GitHub ───────────────────────────────────────────────────

write_vault_secret "blanketops/environments/github/webhook/secret" "<REPLACE_WITH_WEBHOOK_SECRET>"
write_vault_secret "blanketops/environments/github/api/token" "<REPLACE_WITH_GITHUB_TOKEN>"

# ── Crossplane ───────────────────────────────────────────────

write_vault_secret "blanketops/environments/crossplane/github/token" "<REPLACE_WITH_CROSSPLANE_GITHUB_TOKEN>"

echo ""
echo "Done. Verify with: curl -H \"X-Vault-Token: $VAULT_TOKEN\" $VAULT_ADDR/v1/secret/metadata"
