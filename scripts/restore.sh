#!/usr/bin/env bash
set -e

echo "============================================"
echo "  📥 Restoring FULL Server from Cloudflare R2"
echo "============================================"

# Configure AWS CLI for Cloudflare R2 (S3 compatible)
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="auto"
R2_ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

# Try the new full-server backup first, fall back to old world-only backup
RESTORED=false

if aws s3api head-object --bucket "$R2_BUCKET_NAME" --key "minecraft-server-latest.tar.gz" --endpoint-url "$R2_ENDPOINT" 2>/dev/null; then
  echo "📦 Full server backup found in R2. Downloading..."
  aws s3 cp "s3://${R2_BUCKET_NAME}/minecraft-server-latest.tar.gz" ./minecraft-server-latest.tar.gz --endpoint-url "$R2_ENDPOINT"

  ARCHIVE_SIZE=$(du -h minecraft-server-latest.tar.gz | cut -f1)
  echo "📂 Extracting full server files ($ARCHIVE_SIZE)..."
  tar -xzf minecraft-server-latest.tar.gz
  rm -f minecraft-server-latest.tar.gz
  RESTORED=true

  # Show what was restored
  echo ""
  echo "✅ Restored from R2:"
  [ -d "world" ] && echo "  📁 world/"
  [ -d "world_nether" ] && echo "  📁 world_nether/"
  [ -d "world_the_end" ] && echo "  📁 world_the_end/"
  [ -f "server.properties" ] && echo "  📄 server.properties"
  [ -f "ops.json" ] && echo "  📄 ops.json (operators)"
  [ -f "whitelist.json" ] && echo "  📄 whitelist.json"
  [ -f "banned-players.json" ] && echo "  📄 banned-players.json"
  [ -d "plugins" ] && echo "  📁 plugins/ (configs + data)"
  [ -d "config" ] && echo "  📁 config/ (paper/purpur settings)"
  [ -f "bukkit.yml" ] && echo "  📄 bukkit.yml"
  [ -f "spigot.yml" ] && echo "  📄 spigot.yml"
  [ -f "purpur.yml" ] && echo "  📄 purpur.yml"
  echo ""

# Fall back to old world-only backup format
elif aws s3api head-object --bucket "$R2_BUCKET_NAME" --key "minecraft-world-latest.tar.gz" --endpoint-url "$R2_ENDPOINT" 2>/dev/null; then
  echo "📦 Legacy world backup found in R2. Downloading..."
  aws s3 cp "s3://${R2_BUCKET_NAME}/minecraft-world-latest.tar.gz" ./minecraft-world-latest.tar.gz --endpoint-url "$R2_ENDPOINT"

  echo "📂 Extracting world files..."
  tar -xzf minecraft-world-latest.tar.gz
  rm -f minecraft-world-latest.tar.gz
  RESTORED=true
  echo "✅ World files restored (legacy format). Next backup will use full format."
fi

if [ "$RESTORED" = true ]; then
  echo "✅ Server restore completed!"
else
  echo "ℹ️ No backup found in R2. A fresh server will be generated."
fi
