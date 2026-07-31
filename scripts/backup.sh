#!/usr/bin/env bash
set -e

echo "=== Backing up server to Cloudflare R2 ==="

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

# Server icon
[ -f "server-icon.png" ] && TARGET_FILES+=("server-icon.png")

# Plugins (configs, data, JARs)
[ -d "plugins" ] && TARGET_FILES+=("plugins")

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  echo "WARNING: No server files found to backup."
  exit 0
fi

echo "Archiving ${#TARGET_FILES[@]} items..."
tar -czf minecraft-server-latest.tar.gz "${TARGET_FILES[@]}"
ARCHIVE_SIZE=$(du -h minecraft-server-latest.tar.gz | cut -f1)
echo "Archive size: $ARCHIVE_SIZE"

# Upload ONLY the latest file (overwrites previous)
# No timestamped copies — saves R2 storage (free tier = 10 GB)
echo "Uploading to R2 (overwriting previous backup)..."
aws s3 cp ./minecraft-server-latest.tar.gz "s3://${R2_BUCKET_NAME}/minecraft-server-latest.tar.gz" --endpoint-url "$R2_ENDPOINT"

rm -f minecraft-server-latest.tar.gz
echo "Backup done! ($ARCHIVE_SIZE)"
