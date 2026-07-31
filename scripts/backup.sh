#!/usr/bin/env bash
set -e

echo "============================================"
echo "  📦 Backing Up FULL Server to Cloudflare R2"
echo "============================================"

# Configure AWS CLI for Cloudflare R2
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# ━━━ Collect ALL important server files ━━━
TARGET_FILES=()

# World directories (player builds, terrain, entities)
[ -d "world" ] && TARGET_FILES+=("world")
[ -d "world_nether" ] && TARGET_FILES+=("world_nether")
[ -d "world_the_end" ] && TARGET_FILES+=("world_the_end")

# Server config files
[ -f "server.properties" ] && TARGET_FILES+=("server.properties")
[ -f "bukkit.yml" ] && TARGET_FILES+=("bukkit.yml")
[ -f "spigot.yml" ] && TARGET_FILES+=("spigot.yml")
[ -f "purpur.yml" ] && TARGET_FILES+=("purpur.yml")
[ -f "paper.yml" ] && TARGET_FILES+=("paper.yml")
[ -d "config" ] && TARGET_FILES+=("config")

# Player management
[ -f "ops.json" ] && TARGET_FILES+=("ops.json")
[ -f "whitelist.json" ] && TARGET_FILES+=("whitelist.json")
[ -f "banned-players.json" ] && TARGET_FILES+=("banned-players.json")
[ -f "banned-ips.json" ] && TARGET_FILES+=("banned-ips.json")
[ -f "usercache.json" ] && TARGET_FILES+=("usercache.json")
[ -f "permissions.yml" ] && TARGET_FILES+=("permissions.yml")

# Plugins (configs, data, JARs)
[ -d "plugins" ] && TARGET_FILES+=("plugins")

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  echo "⚠️ No server files found to backup."
  exit 0
fi

echo "🗜️ Archiving ${#TARGET_FILES[@]} items: ${TARGET_FILES[*]}"
tar -czf minecraft-server-latest.tar.gz "${TARGET_FILES[@]}"
ARCHIVE_SIZE=$(du -h minecraft-server-latest.tar.gz | cut -f1)
echo "📦 Archive size: $ARCHIVE_SIZE"

echo "🚀 Uploading to Cloudflare R2 bucket: ${R2_BUCKET_NAME}..."
aws s3 cp ./minecraft-server-latest.tar.gz "s3://${R2_BUCKET_NAME}/minecraft-server-latest.tar.gz" --endpoint-url "$R2_ENDPOINT"

# Also save a timestamped backup copy (keep history)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
aws s3 cp ./minecraft-server-latest.tar.gz "s3://${R2_BUCKET_NAME}/backups/server_${TIMESTAMP}.tar.gz" --endpoint-url "$R2_ENDPOINT"

rm -f minecraft-server-latest.tar.gz
echo "✅ Full server backup to R2 completed! ($ARCHIVE_SIZE)"
