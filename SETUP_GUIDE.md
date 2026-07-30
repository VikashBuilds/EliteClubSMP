# 🎮 24/7 Minecraft Server Guide (macOS 14GB RAM + Cloudflare R2 + Web File Manager + SFTP)

> **Server Spec:** macOS (`macos-latest`) — 3 vCPUs, **14 GB RAM** (12 GB dedicated Java Heap)  
> **World Storage:** Cloudflare R2 (Free S3-compatible bucket)  
> **Minecraft Address:** `mc.vikashbuilds.in`  
> **Web File Manager:** `files.vikashbuilds.in` (Port 8080)  
> **SFTP / WinSCP:** Port 22 / playit tunnel

---

## 📂 Step 1: Copy Your Existing Server Files (Local Setup)

If you already have existing Minecraft server files (like `world`, `world_nether`, `world_the_end`, `plugins`, `ops.json`, `whitelist.json`, `server.properties`):

1. Open your existing Minecraft server folder on your computer.
2. Copy all your files and paste them into:
   ```
   c:\Users\Vikash Meena\Desktop\Automations\36-MinecraftServer\
   ```
3. Your local folder should contain:
   - `world/`
   - `world_nether/` (optional)
   - `world_the_end/` (optional)
   - `plugins/` (optional)
   - `server.properties`
   - `scripts/`
   - `.github/`

> **Note:** `.gitignore` is already set up to keep heavy binary downloads like `.jar` or logs clean while tracking your custom configs and worlds!

---

## 📌 Step 2: Create Free Cloudflare R2 Storage Bucket

1. Go to **https://dash.cloudflare.com** → click **R2** in left sidebar.
2. Click **Create bucket**.
3. Bucket name: **`minecraft-world-backup`**.
4. Click **Create Bucket**.
5. Click **Manage R2 API Tokens** → **Create API Token**:
   - Token Name: `minecraft-actions`
   - Permissions: **Object Read & Write**
6. Save:
   - **Access Key ID**
   - **Secret Access Key**
   - **Account ID**

---

## 🌐 Step 3: Configure Public Hostnames in Cloudflare Zero Trust

In your Cloudflare Zero Trust Dashboard (**https://one.dash.cloudflare.com**) under **Networks → Tunnels → Your Tunnel → Public Hostnames**:

| Subdomain | Domain | Type | URL / Target | Purpose |
|---|---|---|---|---|
| `mc` | `vikashbuilds.in` | `TCP` | `localhost:25565` | Minecraft Java Server Address |
| `files` | `vikashbuilds.in` | `HTTP` | `localhost:8080` | Web File Manager (cPanel style) |

---

## 🔐 Step 4: Add GitHub Secrets

Go to **https://github.com/VikashBuilds/minecraft-server** → **Settings** → **Secrets and variables** → **Actions**:

| Secret Name | Description | Default / Example |
|---|---|---|
| `R2_ACCOUNT_ID` | Cloudflare Account ID | `<YOUR_ACCOUNT_ID>` |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 Access Key | `<YOUR_ACCESS_KEY_ID>` |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 Secret Key | `<YOUR_SECRET_ACCESS_KEY>` |
| `R2_BUCKET_NAME` | `minecraft-world-backup` | `minecraft-world-backup` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel Token | `<YOUR_TUNNEL_TOKEN>` |
| `PLAYIT_SECRET_KEY` | *(Optional)* playit.gg secret | `<YOUR_PLAYIT_KEY>` |
| `SFTP_PASSWORD` | *(Optional)* Password for SFTP | `Vikash@0436` |

---

## 🚀 Step 5: Push Repository & Start Server

Run in your terminal:

```bash
cd "c:\Users\Vikash Meena\Desktop\Automations\36-MinecraftServer"
git init
git remote add origin https://VikashBuilds@github.com/VikashBuilds/minecraft-server.git
git add .
git commit -m "feat: 24/7 minecraft server with Web File Manager & SFTP"
git branch -M main
git push -u origin main
```

Then go to **GitHub Actions** → **Minecraft Server 24/7 (14GB macOS)** → click **Run workflow**.

---

## 📁 Managing Server Files Live (2 Ways)

### Method 1: Web File Manager (Browser) 🌐
1. Open **`https://files.vikashbuilds.in`** in your browser.
2. Login credentials:
   - **Username:** `admin`
   - **Password:** `admin123` (changeable in filebrowser settings)
3. You can drag-and-drop plugins, edit `server.properties`, upload new worlds, download logs, and edit any file live while the server is running!

### Method 2: SFTP / WinSCP / FileZilla 📁
1. Open **FileZilla** or **WinSCP**.
2. Host: `mc.vikashbuilds.in` (or your playit SFTP address)
3. Port: `22` (or your playit SFTP port)
4. Protocol: **SFTP**
5. Username: `runner`
6. Password: `Vikash@0436` (or whatever you set in `SFTP_PASSWORD` secret)
