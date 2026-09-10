#!/bin/sh
# Entrypoint for the committed NeoForge server.
# Turns environment variables into server config, then launches the server.
set -e

: "${MEMORY:=4G}"
: "${INIT_MEMORY:=1G}"
: "${EULA:=FALSE}"
: "${RCON_PASSWORD:=}"

cd /server

# --- Minecraft EULA ---------------------------------------------------------
case "$(printf '%s' "$EULA" | tr '[:upper:]' '[:lower:]')" in
  true|1|yes|y) echo "eula=true"  > eula.txt ;;
  *)            echo "eula=false" > eula.txt ;;
esac

# --- RCON -------------------------------------------------------------------
if [ -f server.properties ]; then
  if [ -n "$RCON_PASSWORD" ]; then
    sed -i "s/^enable-rcon=.*/enable-rcon=true/"    server.properties
    sed -i "s/^rcon.password=.*/rcon.password=${RCON_PASSWORD}/" server.properties
  else
    sed -i "s/^enable-rcon=.*/enable-rcon=false/"   server.properties
  fi
fi

# --- Runtime dirs -----------------------------------------------------------
mkdir -p world logs crash-reports config defaultconfigs mods runtime

echo "[entrypoint] Starting NeoForge 21.11.45 for Minecraft 1.21.11 (heap ${INIT_MEMORY}/${MEMORY})"

exec java -Xms"$INIT_MEMORY" -Xmx"$MEMORY" \
  @libraries/net/neoforged/neoforge/21.11.45/unix_args.txt \
  nogui "$@"
