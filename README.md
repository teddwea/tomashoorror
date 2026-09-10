# Minecraft 1.21.11 NeoForge Server (Dokploy-ready)

A complete, ready-to-run **Minecraft 1.21.11** server running
**NeoForge 21.11.45**. The full server install (NeoForge + Minecraft server
jar + every library + configs) is committed in this repo, wrapped in a
Dockerfile + Docker Compose stack so you can host it on **Dokploy** and manage
everything through **GitHub**.

- Full server lives in [`server/`](server/) — not just a mods folder.
- Mods are managed in [`mods/`](mods/) and mounted into the server.
- World + logs persist in Docker named volumes across redeploys.
- One command to deploy on Dokploy; optional auto-deploy on git push.

---

## Repository layout

```
.
├── Dockerfile                 # builds a Java 21 image around server/
├── docker-entrypoint.sh       # applies EULA/RCON/RAM env, then starts the server
├── docker-compose.yml         # the stack Dokploy deploys
├── .env.example               # copy to .env / paste into Dokploy
├── .dockerignore
├── .gitignore
├── mods/                      # your NeoForge 1.21.11 server mods
├── server/                    # <-- the FULL NeoForge 1.21.11 install
│   ├── libraries/             # NeoForge + Minecraft server jars & libraries
│   ├── config/                # NeoForge config files
│   ├── defaultconfigs/
│   ├── server.properties
│   ├── eula.txt
│   ├── ops.json
│   ├── whitelist.json
│   ├── banned-ips.json
│   ├── banned-players.json
│   ├── run.sh / run.bat
│   └── user_jvm_args.txt
└── .github/workflows/deploy.yml
```

The `server/` folder is a normal NeoForge dedicated-server install. You can run
it directly, inspect it, or reinstall it from scratch — the Docker stack simply
packages it.

---

## 1. Configure

```bash
cp .env.example .env
```

| Variable        | Default     | Meaning                                        |
| --------------- | ----------- | ---------------------------------------------- |
| `EULA`          | `TRUE`      | Set `TRUE` to accept the Minecraft EULA        |
| `SERVER_PORT`   | `25565`     | Host port players connect to                   |
| `MEMORY`        | `4G`        | Max JVM heap                                   |
| `INIT_MEMORY`   | `1G`        | Initial JVM heap                               |
| `RCON_PASSWORD` | _(example)_ | Set a strong value to enable RCON; empty = off |
| `TZ`            | `UTC`       | Container timezone                             |

Gameplay settings (difficulty, motd, max-players, online-mode, whitelist, …)
live in [`server/server.properties`](server/server.properties) and are versioned
in git. Edit that file, commit, redeploy.

> By setting `EULA=TRUE` you agree to <https://aka.ms/MinecraftEULA>.

---

## 2. Run locally (optional)

### With Docker (recommended)

```bash
docker compose up --build -d
docker compose logs -f minecraft
```

Wait for `Done (x.xxxs)! For help, type "help"`. Connect to
`localhost:25565`. `docker compose down` stops it and keeps the world.

### Without Docker

The committed install also runs directly (Java 21 required):

```bash
# Linux / macOS
cd server && ./run.sh nogui

# Windows
cd server && run.bat
```

---

## 3. Push to GitHub

The vanilla server jar is ~54 MB, which is under GitHub's 100 MB hard limit but
above its 50 MB warning. Git LFS is recommended:

```bash
git lfs install
git lfs track "server/libraries/**/*.jar"
git add .gitattributes
```

Then commit and push:

```bash
git init
git add .
git commit -m "Full NeoForge 1.21.11 server"
git branch -M main
git remote add origin https://github.com/<you>/<repo>.git
git push -u origin main
```

`.env`, the world and logs are git-ignored on purpose. Never commit secrets.

---

## 4. Deploy on Dokploy

1. Log in to Dokploy → **Create Project** (e.g. `minecraft`).
2. **Create Service → Compose**.
3. Under **Provider / Source**, connect GitHub, pick this repo, branch `main`,
   and compose path `docker-compose.yml`.
4. Open the **Environment** tab and paste your `.env` values. At minimum set
   `EULA=TRUE`, a strong `RCON_PASSWORD`, and `SERVER_PORT`.
5. Click **Deploy**. Dokploy builds the Dockerfile (Java 21 + committed
   `server/`) and starts it. Watch the logs for
   `Done (x.xxxs)! For help, type "help"`.
6. Allow inbound **TCP 25565** in your VPS firewall / provider security group
   (add **UDP 25565** only if you use Geyser/Bedrock cross-play).

> Dokploy's Traefik proxy handles **HTTP** only. Minecraft is raw **TCP**, so do
> **not** attach a Dokploy domain — connect to `YOUR_SERVER_IP:25565` (or
> `tomas.teddwa.xyz` once the DNS below is set up).

### DNS for `tomas.teddwa.xyz`

Point the subdomain at your VPS's public IP with an **A record**:

| Type | Name                                  | Value         | TTL  |
| ---- | ------------------------------------- | ------------- | ---- |
| A    | `tomas` (or `tomas.teddwa.xyz`)       | `YOUR_VPS_IP` | Auto |

Players can then connect to **`tomas.teddwa.xyz`** — the Minecraft client uses
port `25565` by default. Make sure TCP `25565` is open in the VPS firewall /
provider security group.

Only if you run the server on a **non-default** port do you need an SRV record
(Minecraft looks up `_minecraft._tcp.<address>` before falling back to
`<address>:25565`):

| Type | Name                    | Target             | Port    | Priority | Weight |
| ---- | ----------------------- | ------------------ | ------- | -------- | ------ |
| SRV  | `_minecraft._tcp.tomas` | `tomas.teddwa.xyz` | `25565` | `0`      | `5`    |

> Do **not** add `tomas.teddwa.xyz` as a Domain on the Dokploy service — Traefik
> only routes HTTP/HTTPS. Minecraft keeps using the raw TCP port.

---

## 5. Adding mods

1. Download NeoForge **1.21.11** server mods.
2. Drop the `.jar` files into `mods/`.
3. Commit and push:

```bash
git add mods/
git commit -m "Add mods"
git push
```

4. Redeploy in Dokploy (or let the auto-deploy workflow do it). `mods/` is
   bind-mounted to `/server/mods`, so new jars load on next start.

Tips:

- Only **server-side** mods. Client-only mods (shaders, minimap, JEI) go in
  each player's client.
- Mods must match **NeoForge 1.21.11** exactly.
- For large mod sets use Git LFS: `git lfs track "mods/*.jar"`.

---

## 6. Auto-deploy on push (optional)

`.github/workflows/deploy.yml` validates the compose file and triggers a
Dokploy deployment on every push to `main`.

1. Dokploy → your Compose service → **Webhooks** → copy the deploy webhook URL.
2. GitHub → **Settings → Secrets and variables → Actions** → new secret named
   `DOKPLOY_WEBHOOK_URL` with that URL.
3. Push to `main`.

---

## 7. Updating NeoForge / Minecraft

To install a newer NeoForge build for the same MC version:

```bash
# 1. Back up the world first (see below)
# 2. Re-run the installer into server/
java -jar neoforge-21.11.xx-installer.jar --installServer server
```

To move to a **different Minecraft version**, install that version's NeoForge
into `server/` (e.g. `neoforge-<newver>-installer.jar`) and commit the changed
files. Always back up the world first — newer versions can upgrade the world
format irreversibly.

Download installers: <https://neoforged.net> or
<https://maven.neoforged.net/releases/net/neoforged/neoforge/>.

---

## 8. Backups

The world lives in the `minecraft-world` volume:

```bash
docker run --rm \
  -v tomashoorror_minecraft-world:/data \
  -v "$PWD":/backup alpine \
  tar czf /backup/world-backup-$(date +%F).tar.gz -C /data .
```

---

## 9. Useful commands

| Task              | Command                                                       |
| ----------------- | ------------------------------------------------------------- |
| Live logs         | `docker compose logs -f minecraft`                            |
| Restart           | `docker compose restart minecraft`                            |
| Shell into server | `docker compose exec minecraft sh`                            |
| Grant OP          | `docker exec -i <container> rcon-cli op <player>`             |
| Stop (keep world) | `docker compose down`                                         |

---

## References

- NeoForge: <https://neoforged.net>
- Dokploy docs: <https://docs.dokploy.com>
- Minecraft EULA: <https://aka.ms/MinecraftEULA>
