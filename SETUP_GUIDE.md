# 🎮 24/7 Minecraft Server Guide (macOS 14GB RAM + Cloudflare R2)

> **Server Spec:** macOS (`macos-latest`) — 3 vCPUs, **14 GB RAM** (12 GB dedicated Java Heap)  
> **World Storage:** Cloudflare R2 (Free S3-compatible bucket)  
> **Domain Address:** `mc.vikashbuilds.in`

---

## 📌 Step 1: Create Free Cloudflare R2 Storage Bucket

1. Go to **https://dash.cloudflare.com** → click **R2** in left sidebar.
2. Click **Create bucket**.
3. Bucket name: **`minecraft-world-backup`** (or your preferred name).
4. Click **Create Bucket**.
5. Click **Manage R2 API Tokens** (on the right sidebar under Account details).
6. Click **Create API Token**:
   - Token Name: `minecraft-actions`
   - Permissions: **Object Read & Write**
   - Click **Create API Token**.
7. Copy and save:
   - **Access Key ID**
   - **Secret Access Key**
   - **Account ID** (found on R2 overview page URL: `dash.cloudflare.com/<ACCOUNT_ID>/r2`)

---

## 📌 Step 2: Configure Cloudflare Tunnel / playit.gg

You have two options for connecting players to `mc.vikashbuilds.in`:

### Option A: `playit.gg` + Cloudflare DNS (Recommended for Minecraft Raw TCP)
1. Go to **https://playit.gg** → sign up for a free account.
2. Create an agent token → copy your **Secret Key**.
3. In `playit.gg` dashboard, add a **Custom Domain / CNAME**:
   - Point your assigned `playit` domain (e.g. `xyz.ply.gg`) to `mc.vikashbuilds.in`.
4. In Cloudflare DNS for **`vikashbuilds.in`**:
   - Add **CNAME** record:
     - Name: `mc`
     - Target: `xyz.ply.gg`
     - Proxy status: **DNS Only (Grey Cloud)** ⚙️

### Option B: Cloudflare Zero Trust Named Tunnel
1. Go to **https://one.dash.cloudflare.com** (Zero Trust) → **Networks** → **Tunnels**.
2. Click **Create a tunnel** → select **Cloudflared**.
3. Tunnel Name: `minecraft-server`.
4. Copy the **Tunnel Token**.
5. Add Public Hostname:
   - Subdomain: `mc`
   - Domain: `vikashbuilds.in`
   - Type: `TCP`
   - URL: `localhost:25565`

---

## 📌 Step 3: Add Secrets to GitHub Repository

1. Go to your GitHub repository (**`https://github.com/VikashBuilds/minecraft-server`**)
2. Go to **Settings** → **Secrets and variables** → **Actions**.
3. Add the following secrets:

| Secret Name | Description / Value |
|---|---|
| `R2_ACCOUNT_ID` | Your Cloudflare Account ID |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 API Token Access Key |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 API Token Secret Key |
| `R2_BUCKET_NAME` | `minecraft-world-backup` |
| `PLAYIT_SECRET_KEY` | *(Optional if using playit.gg)* Your playit.gg secret key |
| `CLOUDFLARE_TUNNEL_TOKEN` | *(Optional if using Cloudflare Tunnel)* Your Cloudflare tunnel token |

---

## 📌 Step 4: Push Repository & Trigger Server

In your terminal:

```bash
cd "c:\Users\Vikash Meena\Desktop\Automations\36-MinecraftServer"
git init
git remote add origin https://VikashBuilds@github.com/VikashBuilds/minecraft-server.git
git add .
git commit -m "feat: 24/7 minecraft server on macOS 14GB RAM with R2 backup"
git branch -M main
git push -u origin main
```

After pushing:
1. Go to **https://github.com/VikashBuilds/minecraft-server/actions**.
2. Click **Minecraft Server 24/7 (14GB macOS)** → click **Run workflow**.

---

## 🎮 Joining Your Server

In Minecraft (Java Edition 1.21.x):
1. Click **Multiplayer** → **Add Server**.
2. Server Address: **`mc.vikashbuilds.in`**
3. Click **Done** & Join! 🚀
