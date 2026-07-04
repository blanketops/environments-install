#!/bin/bash
# ============================================================
# bootstrap-gcp-secrets.sh
#
# Creates all blanketops secrets in GCP Secret Manager.
# Run once before applying cluster-secret-store-gcp.yaml.
#
# Prerequisites:
#   gcloud cli installed and authenticated
#   gcloud auth login
#   Secret Manager API enabled:
#     gcloud services enable secretmanager.googleapis.com
#
# GCP Secret Manager naming:
#   Does not support "/" — paths flattened with "_"
#   /blanketops/git/ssh-privatekey → blanketops_git_ssh-privatekey
# ============================================================

PROJECT_ID="<REPLACE_WITH_GCP_PROJECT_ID>"

echo "Bootstrapping BlanketOps secrets in GCP Secret Manager: $PROJECT_ID"
echo ""

# ── Git SSH ──────────────────────────────────────────────────

echo "Creating blanketops_git_ssh-privatekey..."
echo -n "$(cat ~/.ssh/id_ed25519)" | \
  gcloud secrets create blanketops_git_ssh-privatekey \
  --data-file=- \
  --project="$PROJECT_ID"

echo "Creating blanketops_git_ssh-publickey..."
echo -n "$(cat ~/.ssh/id_ed25519.pub)" | \
  gcloud secrets create blanketops_git_ssh-publickey \
  --data-file=- \
  --project="$PROJECT_ID"

echo "Creating blanketops_git_known-hosts..."
ssh-keyscan github.com 2>/dev/null | \
  gcloud secrets create blanketops_git_known-hosts \
  --data-file=- \
  --project="$PROJECT_ID"

# ── Registry ─────────────────────────────────────────────────

echo "Creating blanketops_registry_config..."
DOCKER_AUTH=$(echo -n "<USERNAME>:<TOKEN>" | base64)
echo -n "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$DOCKER_AUTH\"}}}" | \
  gcloud secrets create blanketops_registry_config \
  --data-file=- \
  --project="$PROJECT_ID"

# ── GitHub ───────────────────────────────────────────────────

echo "Creating blanketops_github_webhook_secret..."
echo -n "<REPLACE_WITH_WEBHOOK_SECRET>" | \
  gcloud secrets create blanketops_github_webhook_secret \
  --data-file=- \
  --project="$PROJECT_ID"

echo "Creating blanketops_github_api_token..."
echo -n "<REPLACE_WITH_GITHUB_TOKEN>" | \
  gcloud secrets create blanketops_github_api_token \
  --data-file=- \
  --project="$PROJECT_ID"

# ── Crossplane ───────────────────────────────────────────────

echo "Creating blanketops_crossplane_github_token..."
echo -n "<REPLACE_WITH_CROSSPLANE_GITHUB_TOKEN>" | \
  gcloud secrets create blanketops_crossplane_github_token \
  --data-file=- \
  --project="$PROJECT_ID"

echo ""
echo "Done. Verify with:"
echo "  gcloud secrets list --project=$PROJECT_ID --filter='name~blanketops'"

# ── GCP IAM ──────────────────────────────────────────────────
# Grant the Service Account access to secrets:
#
# SA="<SA_NAME>@$PROJECT_ID.iam.gserviceaccount.com"
#
# For each secret:
# gcloud secrets add-iam-policy-binding blanketops_git_ssh-privatekey \
#   --member="serviceAccount:$SA" \
#   --role="roles/secretmanager.secretAccessor" \
#   --project="$PROJECT_ID"
#
# Or grant project-wide (simpler, less granular):
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#   --member="serviceAccount:$SA" \
#   --role="roles/secretmanager.secretAccessor"
