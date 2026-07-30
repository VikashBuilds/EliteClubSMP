#!/usr/bin/env bash
set -e

echo "============================================"
echo "  🚀 Starting PaperMC Minecraft Server (14GB RAM macOS)"
echo "============================================"

# Accept Minecraft EULA
echo "eula=true" > eula.txt

# Ensure server binds to all interfaces (critical for tunnels)
if [ -f "server.properties" ]; then
  # Make sure server-ip is empty (binds to 0.0.0.0)
  if grep -q "^server-ip=" server.properties; then
    sed -i '' 's/^server-ip=.*/server-ip=/' server.properties
  else
    echo "server-ip=" >> server.properties
  fi
  echo "✅ server.properties configured (binding to 0.0.0.0:25565)"
fi

# Download latest Purpur 1.21.4 JAR if not present
if [ ! -f "paper.jar" ]; then
  echo "📥 Downloading Purpur 1.21.4 server JAR..."
  DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/1.21.4/latest/download"
  curl -sL -o paper.jar "$DOWNLOAD_URL"

  # Verify download
  FILE_SIZE=$(stat -f%z paper.jar 2>/dev/null || stat -c%s paper.jar 2>/dev/null || echo "0")
  if [ "$FILE_SIZE" -lt 1000000 ]; then
    echo "❌ Downloaded JAR is too small (${FILE_SIZE} bytes). Trying Paper fallback..."
    rm -f paper.jar
    curl -sL -o paper.jar "https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/latest/downloads/paper-1.21.4-latest.jar" || {
      echo "❌ Paper fallback also failed. Cannot start server."
      exit 1
    }
  fi

  echo "✅ Downloaded paper.jar (1.21.4) successfully ($(du -h paper.jar | cut -f1))"
fi

# High-performance JVM flags optimized for 14GB RAM & Aikar's Flags
JAVA_FLAGS=(
  -Xms4G
  -Xmx12G
  -XX:+UseG1GC
  -XX:+ParallelRefProcEnabled
  -XX:MaxGCPauseMillis=200
  -XX:+UnlockExperimentalVMOptions
  -XX:+DisableExplicitGC
  -XX:+AlwaysPreTouch
  -XX:G1NewSizePercent=30
  -XX:G1MaxNewSizePercent=40
  -XX:G1HeapRegionSize=8M
  -XX:G1ReservePercent=20
  -XX:G1HeapWastePercent=5
  -XX:G1MixedGCCountTarget=4
  -XX:InitiatingHeapOccupancyPercent=15
  -XX:G1MixedGCLiveThresholdPercent=90
  -XX:G1RSetUpdatingPauseTimePercent=5
  -XX:SurvivorRatio=32
  -XX:+PerfDisableSharedMem
  -XX:MaxTenuringThreshold=1
)

echo "☕ Launching Java process with 12GB RAM..."
echo "📡 The playit.gg plugin will handle TCP tunneling automatically."
echo "🔍 Watch the logs below for your server's public address (*.ply.gg)"
echo ""

# Create named pipe for sending commands (e.g., "stop") to the server
PIPE="/tmp/mc_cmd"
rm -f "$PIPE"
mkfifo "$PIPE"

# Start server reading from both pipe and stdin
# This allows sending "stop" command via: echo "stop" > /tmp/mc_cmd
tail -f "$PIPE" | java "${JAVA_FLAGS[@]}" -jar paper.jar nogui
