#!/usr/bin/env bash
set -e

echo "============================================"
echo "  🚀 Starting PaperMC Minecraft Server (14GB RAM macOS)"
echo "============================================"

# Accept Minecraft EULA
echo "eula=true" > eula.txt

# Download latest PaperMC 1.21 JAR if not present
if [ ! -f "paper.jar" ]; then
  echo "📥 Downloading PaperMC 1.21.1..."
  PAPER_PROJECT="paper"
  PAPER_VERSION="1.21.1"
  BUILD_INFO=$(curl -s https://api.papermc.io/v2/projects/${PAPER_PROJECT}/versions/${PAPER_VERSION})
  LATEST_BUILD=$(echo "$BUILD_INFO" | jq -r '.builds[-1]')
  DOWNLOAD_URL="https://api.papermc.io/v2/projects/${PAPER_PROJECT}/versions/${PAPER_VERSION}/builds/${LATEST_BUILD}/downloads/${PAPER_PROJECT}-${PAPER_VERSION}-${LATEST_BUILD}.jar"
  
  echo "Downloading build #${LATEST_BUILD} from ${DOWNLOAD_URL}..."
  curl -o paper.jar "$DOWNLOAD_URL"
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
  -XX:SurviorRatio=32
  -XX:+PerfDisableSharedMem
  -XX:MaxTenuringThreshold=1
)

echo "☕ Launching Java process with 12GB RAM..."
java "${JAVA_FLAGS[@]}" -jar paper.jar nogui
