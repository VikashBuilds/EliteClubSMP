#!/usr/bin/env bash
set -e

echo "============================================"
echo "  📦 Backing Up Minecraft World to Cloudflare R2"
echo "============================================"

# Configure AWS CLI for Cloudflare R2
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# Sync server data into archive
TARGET_DIRS=()
[ -d "world" ] && TARGET_DIRS+=("world")
[ -d "world_nether" ] && TARGET_DIRS+=("world_nether")
[ -d "world_the_end" ] && TARGET_DIRS+=("world_the_end")
[ -f "server.properties" ] && TARGET_DIRS+=("server.properties")
[ -d "plugins" ] && TARGET_DIRS+=("plugins")

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
  echo "⚠️ No world directories found to backup."
  exit 0
fi

echo "🗜️ Archiving world files (${TARGET_DIRS[*]})..."
tar -czf minecraft-world-latest.tar.gz "${TARGET_DIRS[@]}"

echo "🚀 Uploading archive to Cloudflare R2 bucket: ${R2_BUCKET_NAME}..."
aws s3 cp ./minecraft-world-latest.tar.gz "s3://${R2_BUCKET_NAME}/minecraft-world-latest.tar.gz" --endpoint-url "$R2_ENDPOINT"

# Also save a timestamped backup copy
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
aws s3 cp ./minecraft-world-latest.tar.gz "s3://${R2_BUCKET_NAME}/backups/world_${TIMESTAMP}.tar.gz" --endpoint-url "$R2_ENDPOINT"

rm -f minecraft-world-latest.tar.gz
echo "✅ Cloudflare R2 Backup Completed Successfully!"
