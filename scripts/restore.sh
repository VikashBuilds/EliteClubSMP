#!/usr/bin/env bash
set -e

echo "============================================"
echo "  📥 Restoring Minecraft World from Cloudflare R2"
echo "============================================"

# Configure AWS CLI for Cloudflare R2 (S3 compatible)
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# Check if backup exists in R2
if aws s3api head-object --bucket "$R2_BUCKET_NAME" --key "minecraft-world-latest.tar.gz" --endpoint-url "$R2_ENDPOINT" 2>/dev/null; then
  echo "📦 Backup archive found in R2. Downloading..."
  aws s3 cp "s3://${R2_BUCKET_NAME}/minecraft-world-latest.tar.gz" ./minecraft-world-latest.tar.gz --endpoint-url "$R2_ENDPOINT"
  
  echo "📂 Extracting world files..."
  tar -xzf minecraft-world-latest.tar.gz
  rm -f minecraft-world-latest.tar.gz
  echo "✅ World files restored successfully!"
else
  echo "ℹ️ No existing world backup found in R2. A fresh world will be generated."
fi
