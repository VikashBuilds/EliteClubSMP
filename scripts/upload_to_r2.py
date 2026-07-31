"""
Upload your old Minecraft server to Cloudflare R2.
Run this ONCE to seed R2 with your existing server data.

Usage:
  python scripts/upload_to_r2.py

Required environment variables (or edit the values below):
  R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME
"""
import os
import sys
import tarfile
import tempfile

# ━━━ PASTE YOUR R2 CREDENTIALS HERE (or set as env vars) ━━━
R2_ACCOUNT_ID = os.environ.get("R2_ACCOUNT_ID", "")
R2_ACCESS_KEY_ID = os.environ.get("R2_ACCESS_KEY_ID", "")
R2_SECRET_ACCESS_KEY = os.environ.get("R2_SECRET_ACCESS_KEY", "")
R2_BUCKET_NAME = os.environ.get("R2_BUCKET_NAME", "")

# Path to your old minecraft server
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MINECRAFT_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "minecraft")

# Files to backup
BACKUP_ITEMS = [
    "world", "world_nether", "world_the_end",
    "server.properties", "bukkit.yml", "spigot.yml", "purpur.yml",
    "config",
    "ops.json", "whitelist.json", "banned-players.json", "banned-ips.json",
    "usercache.json", "permissions.yml", "wepif.yml", "commands.yml",
    "server-icon.png",
    "plugins",
]

def main():
    if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME]):
        print("❌ Missing R2 credentials!")
        print("   Set these env vars: R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME")
        print("   Or edit the values at the top of this script.")
        sys.exit(1)

    if not os.path.isdir(MINECRAFT_DIR):
        print(f"❌ Minecraft directory not found: {MINECRAFT_DIR}")
        sys.exit(1)

    try:
        import boto3
    except ImportError:
        print("📦 Installing boto3...")
        os.system(f"{sys.executable} -m pip install boto3")
        import boto3

    # Step 1: Create archive
    archive_path = os.path.join(tempfile.gettempdir(), "minecraft-server-latest.tar.gz")
    print(f"📦 Packing server files from: {MINECRAFT_DIR}")

    existing = []
    for item in BACKUP_ITEMS:
        full_path = os.path.join(MINECRAFT_DIR, item)
        if os.path.exists(full_path):
            existing.append(item)
            print(f"  ✅ {item}")
        else:
            print(f"  ⏭️  {item} (not found, skipping)")

    print(f"\n🗜️ Compressing {len(existing)} items...")
    with tarfile.open(archive_path, "w:gz") as tar:
        for item in existing:
            full_path = os.path.join(MINECRAFT_DIR, item)
            tar.add(full_path, arcname=item)
            print(f"  📁 Added: {item}")

    size_mb = os.path.getsize(archive_path) / (1024 * 1024)
    print(f"\n📦 Archive size: {size_mb:.1f} MB")

    # Step 2: Upload to R2
    print(f"\n🚀 Uploading to Cloudflare R2 (bucket: {R2_BUCKET_NAME})...")
    s3 = boto3.client(
        "s3",
        endpoint_url=f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        region_name="auto",
    )

    # Upload with progress
    file_size = os.path.getsize(archive_path)
    uploaded = [0]

    def progress_callback(bytes_transferred):
        uploaded[0] += bytes_transferred
        pct = (uploaded[0] / file_size) * 100
        print(f"\r  ⬆️  {uploaded[0] / (1024*1024):.1f} / {file_size / (1024*1024):.1f} MB ({pct:.0f}%)", end="", flush=True)

    s3.upload_file(
        archive_path,
        R2_BUCKET_NAME,
        "minecraft-server-latest.tar.gz",
        Callback=progress_callback,
    )
    print("\n")

    # Cleanup
    os.remove(archive_path)
    print("✅ Upload complete! Your old server is now in Cloudflare R2.")
    print("   Next workflow run will automatically restore these files! 🎮")


if __name__ == "__main__":
    main()
