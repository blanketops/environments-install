#!/bin/bash
# ============================================================
# bootstrap-aws-secrets.sh
#
# Creates all /blanketops/* secrets in AWS Secrets Manager.
# Run once before applying cluster-secret-store-aws.yaml.
#
# Prerequisites:
#   aws cli configured with sufficient IAM permissions
#   SecretManager:CreateSecret, SecretManager:PutSecretValue
#
# Region: af-south-1 (Cape Town) — change if different
# ============================================================

REGION="af-south-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

echo "Bootstrapping BlanketOps secrets in AWS Secrets Manager"
echo "Region: $REGION | Account: $ACCOUNT"
echo ""

# ── Git SSH ──────────────────────────────────────────────────

echo "Creating /blanketops/git/ssh-privatekey..."
aws secretsmanager create-secret \
  --name "/blanketops/git/ssh-privatekey" \
  --description "BlanketOps git SSH private key for source cloning" \
  --secret-string "$(cat ~/.ssh/id_ed25519)" \
  --region "$REGION"

echo "Creating /blanketops/git/ssh-publickey..."
aws secretsmanager create-secret \
  --name "/blanketops/git/ssh-publickey" \
  --description "BlanketOps git SSH public key" \
  --secret-string "$(cat ~/.ssh/id_ed25519.pub)" \
  --region "$REGION"

echo "Creating /blanketops/git/known-hosts..."
aws secretsmanager create-secret \
  --name "/blanketops/git/known-hosts" \
  --description "BlanketOps git SSH known hosts (GitHub)" \
  --secret-string "$(ssh-keyscan github.com 2>/dev/null)" \
  --region "$REGION"

# ── Registry ─────────────────────────────────────────────────

echo "Creating /blanketops/registry/config..."
# Replace <USERNAME> and <TOKEN> with your Docker Hub credentials
DOCKER_AUTH=$(echo -n "<USERNAME>:<TOKEN>" | base64)
aws secretsmanager create-secret \
  --name "/blanketops/registry/config" \
  --description "BlanketOps Docker registry auth config" \
  --secret-string "{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"$DOCKER_AUTH\"}}}" \
  --region "$REGION"

# ── GitHub ───────────────────────────────────────────────────

echo "Creating /blanketops/github/webhook/secret..."
aws secretsmanager create-secret \
  --name "/blanketops/github/webhook/secret" \
  --description "BlanketOps GitHub webhook HMAC secret" \
  --secret-string "<REPLACE_WITH_WEBHOOK_SECRET>" \
  --region "$REGION"

echo "Creating /blanketops/github/api/token..."
aws secretsmanager create-secret \
  --name "/blanketops/github/api/token" \
  --description "BlanketOps GitHub API token for environments controller" \
  --secret-string "<REPLACE_WITH_GITHUB_TOKEN>" \
  --region "$REGION"

# ── Crossplane ───────────────────────────────────────────────

echo "Creating /blanketops/crossplane/github/token..."
aws secretsmanager create-secret \
  --name "/blanketops/crossplane/github/token" \
  --description "BlanketOps Crossplane GitHub provider token" \
  --secret-string "<REPLACE_WITH_CROSSPLANE_GITHUB_TOKEN>" \
  --region "$REGION"

echo ""
echo "Done. Verify with:"
echo "  aws secretsmanager list-secrets --region $REGION --query 'SecretList[?starts_with(Name, \`/blanketops\`)].Name'"

# ── IAM Policy ───────────────────────────────────────────────
# Attach this policy to the IRSA role for external-secrets:
#
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret"
#       ],
#       "Resource": "arn:aws:secretsmanager:<REGION>:<ACCOUNT>:secret:/blanketops/*"
#     }
#   ]
# }
