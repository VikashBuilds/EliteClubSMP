#!/usr/bin/env bash
# Upload your old Minecraft server files to Cloudflare R2
# Run this script ONCE to seed R2 with your existing server data
set -e

echo "============================================"
echo "  🚀 Uploading Old Server to Cloudflare R2"
echo "============================================"

cd "$(dirname "$0")/../minecraft"

# Collect all important server files
TARGET_FILES=()
[ -d "world" ] && TARGET_FILES+=("world")
[ -d "world_nether" ] && TARGET_FILES+=("world_nether")
[ -d "world_the_end" ] && TARGET_FILES+=("world_the_end")
[ -f "server.properties" ] && TARGET_FILES+=("server.properties")
[ -f "bukkit.yml" ] && TARGET_FILES+=("bukkit.yml")
[ -f "spigot.yml" ] && TARGET_FILES+=("spigot.yml")
[ -f "purpur.yml" ] && TARGET_FILES+=("purpur.yml")
[ -d "config" ] && TARGET_FILES+=("config")
[ -f "ops.json" ] && TARGET_FILES+=("ops.json")
[ -f "whitelist.json" ] && TARGET_FILES+=("whitelist.json")
[ -f "banned-players.json" ] && TARGET_FILES+=("banned-players.json")
[ -f "banned-ips.json" ] && TARGET_FILES+=("banned-ips.json")
[ -f "usercache.json" ] && TARGET_FILES+=("usercache.json")
[ -f "permissions.yml" ] && TARGET_FILES+=("permissions.yml")
[ -f "wepif.yml" ] && TARGET_FILES+=("wepif.yml")
[ -f "commands.yml" ] && TARGET_FILES+=("commands.yml")
[ -f "server-icon.png" ] && TARGET_FILES+=("server-icon.png")
[ -d "plugins" ] && TARGET_FILES+=("plugins")

echo "📦 Packing ${#TARGET_FILES[@]} items..."
tar -czf /tmp/minecraft-server-latest.tar.gz "${TARGET_FILES[@]}"
ARCHIVE_SIZE=$(du -h /tmp/minecraft-server-latest.tar.gz | cut -f1)
echo "📦 Archive size: $ARCHIVE_SIZE"

echo "🚀 Uploading to R2..."
aws s3 cp /tmp/minecraft-server-latest.tar.gz "s3://${R2_BUCKET_NAME}/minecraft-server-latest.tar.gz" --endpoint-url "https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

rm -f /tmp/minecraft-server-latest.tar.gz
echo "✅ Done! Your old server is now in R2. Next workflow run will restore it!"
