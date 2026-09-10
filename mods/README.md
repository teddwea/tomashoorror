# Mods

Drop your NeoForge **1.21.11** server-side mod `.jar` files in this folder, then
commit and push them to GitHub.

```
mods/
  my-mod-1.0.0.jar
  another-mod-2.3.jar
```

Notes:

- Only use mods built for **NeoForge 1.21.11**. Mods for Forge or other MC
  versions will crash the server.
- Server-side mods only. Client-only mods (e.g. shaders, minimaps, JEI) belong
  in players' client mods folder.
- If a mod is required by clients, players must install the same version.
- Large mod packs: prefer Git LFS (`git lfs track "*.jar"`) or a
  `MODRINTH_PROJECTS` env var in `docker-compose.yml`.
- This folder is bind-mounted to `/data/mods` in the container, so any jar here
  is loaded on the next server start/redeploy.
