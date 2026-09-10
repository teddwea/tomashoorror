FROM eclipse-temurin:21-jre

LABEL org.opencontainers.image.title="Minecraft NeoForge 1.21.11 Server" \
      org.opencontainers.image.description="Full NeoForge 21.11.45 server for Minecraft 1.21.11" \
      org.opencontainers.image.source="https://github.com/your-user/your-repo"

ENV MEMORY=2G \
    INIT_MEMORY=512M \
    EULA=FALSE

# Explicit high UID guaranteed not to clash with anything in the base image.
RUN useradd -m -u 21515 -d /server minecraft

WORKDIR /server

COPY --chown=minecraft:minecraft server/ /server/
COPY --chown=minecraft:minecraft mods/ /server/mods/
COPY --chown=minecraft:minecraft docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /server/run.sh \
 && mkdir -p /server/world /server/logs /server/crash-reports /server/config /server/defaultconfigs /server/runtime \
 && mv /server/ops.json /server/whitelist.json /server/banned-players.json /server/banned-ips.json /server/runtime/ \
 && ln -sf runtime/ops.json           /server/ops.json \
 && ln -sf runtime/whitelist.json     /server/whitelist.json \
 && ln -sf runtime/banned-players.json /server/banned-players.json \
 && ln -sf runtime/banned-ips.json    /server/banned-ips.json \
 && ln -sf runtime/usercache.json     /server/usercache.json \
 && ln -sf runtime/usernamecache.json /server/usernamecache.json \
 && chown -R minecraft:minecraft /server

USER minecraft

EXPOSE 25565 25575

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
