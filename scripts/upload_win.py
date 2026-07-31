"""Upload old Minecraft server to Cloudflare R2 (Windows-safe, no emojis)"""
import os, sys, tarfile, tempfile

R2_ACCOUNT_ID = os.environ.get("R2_ACCOUNT_ID", "")
R2_ACCESS_KEY_ID = os.environ.get("R2_ACCESS_KEY_ID", "")
R2_SECRET_ACCESS_KEY = os.environ.get("R2_SECRET_ACCESS_KEY", "")
R2_BUCKET_NAME = os.environ.get("R2_BUCKET_NAME", "")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MINECRAFT_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "minecraft")

BACKUP_ITEMS = [
    "world", "world_nether", "world_the_end",
    "server.properties", "bukkit.yml", "spigot.yml", "purpur.yml",
    "config", "ops.json", "whitelist.json", "banned-players.json",
    "banned-ips.json", "usercache.json", "permissions.yml",
    "wepif.yml", "commands.yml", "server-icon.png", "plugins",
]

def main():
    import boto3

    if not all([R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME]):
        print("ERROR: Missing R2 credentials in env vars")
        sys.exit(1)

    archive_path = os.path.join(tempfile.gettempdir(), "minecraft-server-latest.tar.gz")
    print(f"[1/3] Packing server files from: {MINECRAFT_DIR}")

    existing = []
    for item in BACKUP_ITEMS:
        if os.path.exists(os.path.join(MINECRAFT_DIR, item)):
            existing.append(item)
            print(f"  + {item}")

    print(f"\n[2/3] Compressing {len(existing)} items...")
    with tarfile.open(archive_path, "w:gz") as tar:
        for item in existing:
            full_path = os.path.join(MINECRAFT_DIR, item)
            print(f"  Packing: {item}...")
            tar.add(full_path, arcname=item)

    size_mb = os.path.getsize(archive_path) / (1024 * 1024)
    print(f"\n  Archive size: {size_mb:.1f} MB")

    print(f"\n[3/3] Uploading to Cloudflare R2 (bucket: {R2_BUCKET_NAME})...")
    s3 = boto3.client(
        "s3",
        endpoint_url=f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com",
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        region_name="auto",
    )

    file_size = os.path.getsize(archive_path)
    uploaded = [0]
    last_pct = [0]

    def progress(bytes_transferred):
        uploaded[0] += bytes_transferred
        pct = int((uploaded[0] / file_size) * 100)
        if pct >= last_pct[0] + 5:
            last_pct[0] = pct
            print(f"  Uploaded: {uploaded[0] // (1024*1024)} / {file_size // (1024*1024)} MB ({pct}%)")

    s3.upload_file(archive_path, R2_BUCKET_NAME, "minecraft-server-latest.tar.gz", Callback=progress)

    os.remove(archive_path)
    print("\nDONE! Your old server is now in Cloudflare R2.")
    print("Next workflow run will automatically restore these files!")

if __name__ == "__main__":
    main()
