#!/bin/bash
# ============================================================
# bootstrap-azure-secrets.sh
#
# Creates all blanketops secrets in Azure Key Vault.
# Run once before applying cluster-secret-store-azure.yaml.
#
# Prerequisites:
#   az cli installed and logged in
#   az login
#   Key Vault already created
#
# Azure Key Vault naming:
#   Does not support "/" — paths flattened with "--"
#   /blanketops/git/ssh-privatekey → blanketops--git--ssh-privatekey
# ============================================================

VAULT_NAME="<REPLACE_WITH_VAULT_NAME>"

echo "Bootstrapping BlanketOps secrets in Azure Key Vault: $VAULT_NAME"
echo ""

# ── Git SSH ──────────────────────────────────────────────────

echo "Creating blanketops--git--ssh-privatekey..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--git--ssh-privatekey" \
  --value "$(cat ~/.ssh/id_ed25519)"

echo "Creating blanketops--git--ssh-publickey..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--git--ssh-publickey" \
  --value "$(cat ~/.ssh/id_ed25519.pub)"

echo "Creating blanketops--git--known-hosts..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--git--known-hosts" \
  --value "$(ssh-keyscan github.com 2>/dev/null)"

# ── Registry ─────────────────────────────────────────────────

echo "Creating blanketops--registry--config..."
DOCKER_AUTH=$(echo -n "<USERNAME>:<TOKEN>" | base64)
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--registry--config" \
  --value "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$DOCKER_AUTH\"}}}"

# ── GitHub ───────────────────────────────────────────────────

echo "Creating blanketops--github--webhook--secret..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--github--webhook--secret" \
  --value "<REPLACE_WITH_WEBHOOK_SECRET>"

echo "Creating blanketops--github--api--token..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--github--api--token" \
  --value "<REPLACE_WITH_GITHUB_TOKEN>"

# ── Crossplane ───────────────────────────────────────────────

echo "Creating blanketops--crossplane--github--token..."
az keyvault secret set \
  --vault-name "$VAULT_NAME" \
  --name "blanketops--crossplane--github--token" \
  --value "<REPLACE_WITH_CROSSPLANE_GITHUB_TOKEN>"

echo ""
echo "Done. Verify with:"
echo "  az keyvault secret list --vault-name $VAULT_NAME --query '[].name' -o table"

# ── Azure RBAC ───────────────────────────────────────────────
# Grant the Service Principal or Managed Identity access:
#
# az keyvault set-policy \
#   --name $VAULT_NAME \
#   --object-id <SP_OR_MI_OBJECT_ID> \
#   --secret-permissions get list
#
# Or with RBAC (recommended):
# az role assignment create \
#   --role "Key Vault Secrets User" \
#   --assignee <SP_OR_MI_CLIENT_ID> \
#   --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.KeyVault/vaults/$VAULT_NAME
