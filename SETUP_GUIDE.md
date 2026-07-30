# 🎮 24/7 Minecraft Server Guide (macOS 14GB RAM + Cloudflare R2 + playit.gg)

> **Server Spec:** macOS (`macos-latest`) — 3 vCPUs, **14 GB RAM** (12 GB dedicated Java Heap)  
> **World Storage:** Cloudflare R2 (Free S3-compatible bucket)  
> **Minecraft Address:** `your-server.ply.gg` (via playit.gg TCP tunnel)  
> **Web File Manager:** `files.vikashbuilds.in` (via Cloudflare Tunnel → Port 8080)

---

## ⚠️ Important: How Networking Works

| Service | Protocol | How It Connects | Why |
|---|---|---|---|
| **Minecraft Server** | Raw **TCP** on port 25565 | **playit.gg plugin** (runs inside the Java server) | Cloudflare Tunnels **cannot** proxy raw TCP — they only support HTTP/HTTPS. The playit.gg Minecraft plugin handles TCP tunneling natively. |
| **Web File Manager** | **HTTP** on port 8080 | **Cloudflare Tunnel** → `files.vikashbuilds.in` | Cloudflare Tunnels work perfectly for HTTP services. |

> **Why not `mc.vikashbuilds.in`?** Cloudflare Zero Trust Tunnels do NOT support raw TCP traffic publicly. Setting the type to "TCP" in the dashboard only works for private WARP-connected networks, not public game connections. You must use the `*.ply.gg` address from playit.gg.

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
3. Bucket name: **`eliteclubsmp`**.
4. Click **Create Bucket**.
5. Click **Manage R2 API Tokens** → **Create API Token**:
   - Token Name: `minecraft-actions`
   - Permissions: **Object Read & Write**
6. Save:
   - **Access Key ID**
   - **Secret Access Key**
   - **Account ID**

---

## 🌐 Step 3: Configure Cloudflare Tunnel (File Manager ONLY)

In your Cloudflare Zero Trust Dashboard (**https://one.dash.cloudflare.com**) under **Networks → Tunnels → Your Tunnel → Public Hostnames**:

| Subdomain | Domain | Type | URL / Target | Purpose |
|---|---|---|---|---|
| `files` | `vikashbuilds.in` | `HTTP` | `localhost:8080` | Web File Manager (cPanel style) |

> ❌ **Do NOT add `mc.vikashbuilds.in` as TCP** — it will NOT work for Minecraft. Use playit.gg instead (see Step 6).

---

## 🔐 Step 4: Add GitHub Secrets

Go to **https://github.com/YOUR_USERNAME/YOUR_REPO** → **Settings** → **Secrets and variables** → **Actions**:

| Secret Name | Description | Example |
|---|---|---|
| `R2_ACCOUNT_ID` | Cloudflare Account ID | `28fd32...` |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 Access Key | `c11b9...` |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 Secret Key | `4faea...` |
| `R2_BUCKET_NAME` | R2 Bucket Name | `eliteclubsmp` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel Token | `eyJhI...` |

> **Note:** `PLAYIT_SECRET_KEY` and `SFTP_PASSWORD` are **no longer needed**. The playit.gg plugin handles everything automatically.

---

## 🚀 Step 5: Push Repository & Start Server

Run in your terminal:

```bash
cd "c:\Users\Vikash Meena\Desktop\Automations\36-MinecraftServer"
git add .
git commit -m "fix: use playit.gg plugin for TCP tunnel instead of broken native agent"
git push
```

Then go to **GitHub Actions** → **Minecraft Server 24/7 (14GB macOS)** → click **Run workflow**.

---

## 🎮 Step 6: Get Your Minecraft Server Address (playit.gg — First Time Only)

The **playit.gg Minecraft plugin** runs inside your server and creates a TCP tunnel automatically. On the **first run**, you need to "claim" the tunnel:

### First-Time Setup:
1. **Start the workflow** (Step 5).
2. Go to **GitHub Actions** → click the running job → scroll down to the **"Launch Server"** step.
3. In the live logs, look for a line like:
   ```
   [playit] Visit https://playit.gg/claim/XXXXXX to claim your tunnel
   ```
4. **Click that link** in your browser → log in to your playit.gg account (or create one free).
5. **Claim the tunnel** → playit.gg will assign you a permanent address like:
   ```
   your-server.ply.gg:12345
   ```
6. **That's your Minecraft server address!** Add it to Minecraft → Multiplayer → Add Server.

### After First Claim:
On all future runs, the plugin will automatically reconnect using your claimed tunnel. The address stays the same.

### playit.gg Dashboard:
- Manage your tunnel at **https://playit.gg/account/tunnels**
- You can see live connections, change ports, and add custom domains.

---

## 🌐 Step 7: Web File Manager (`files.vikashbuilds.in`)

The Web File Manager lets you manage all your Minecraft server files, upload plugins, edit `server.properties`, and download logs directly from your browser.

### Access & Log In:
1. Open **`https://files.vikashbuilds.in`** in your browser.
2. Log in with default credentials:
   - **Username:** `admin`
   - **Password:** `admin123`

### How to Use:

| Action | How to Do It |
|---|---|
| 📤 **Upload Plugins / Files** | Drag & drop any `.jar` plugin or `.yml` file into the browser window (or click the **Upload** button at top right). |
| ✏️ **Edit Config Files Live** | Click any file (e.g., `server.properties`, `ops.json`, `whitelist.json`) → an inline code editor opens. Make your changes and click **Save** (💾). |
| 📁 **Upload World Folders** | Click **Upload** → **Upload Directory** → select your local `world/` folder. |
| 📥 **Download Logs / Backups** | Select any file or folder → click the **Download** (📥) button. |
| 🔑 **Change Admin Password** | Click **Settings** (gear icon) on the left sidebar → **My Account** → update password and save. |

---

## 🔄 How the 24/7 Loop Works

```
┌──────────────────────────────────────────────┐
│  GitHub Actions starts workflow               │
│  ↓                                            │
│  1. Restore world from Cloudflare R2          │
│  2. Download Purpur 1.21.4 + playit plugin    │
│  3. Start filebrowser (port 8080)             │
│  4. Start Cloudflare Tunnel (HTTP only)       │
│  5. Launch Minecraft server (port 25565)      │
│     → playit plugin auto-tunnels TCP          │
│  6. Auto-backup every 30 minutes              │
│  7. After 5h 30m → graceful shutdown          │
│  8. Final backup to R2                        │
│  9. Trigger next workflow run                 │
│  ↓                                            │
│  Loop continues indefinitely ♻️               │
└──────────────────────────────────────────────┘
```

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---|---|
| **Can't connect to Minecraft** | Check GitHub Actions live logs for the `playit.gg` claim link. You must claim the tunnel on first use. |
| **`files.vikashbuilds.in` shows 404** | Make sure the Cloudflare Tunnel is running and the public hostname is configured as `HTTP → localhost:8080`. |
| **Server starts but crashes immediately** | Check the Java version — Purpur 1.21.4 requires Java 21. The workflow already sets this up. |
| **World data lost after restart** | Verify your R2 secrets are correct. Check the backup step logs for errors. |
| **playit.gg plugin not loading** | Check `plugins/` folder in the file manager. The plugin JAR should be there. If not, the download may have failed — re-run the workflow. |
