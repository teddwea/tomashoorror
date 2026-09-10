FROM eclipse-temurin:21-jre

LABEL org.opencontainers.image.title="Minecraft NeoForge 1.21.11 Server" \
      org.opencontainers.image.description="Full NeoForge 21.11.45 server for Minecraft 1.21.11" \
      org.opencontainers.image.source="https://github.com/your-user/your-repo"

ENV MEMORY=4G \
    INIT_MEMORY=1G \
    EULA=FALSE

RUN useradd -m -u 1000 -d /server minecraft

WORKDIR /server

COPY --chown=minecraft:minecraft server/ /server/
COPY --chown=minecraft:minecraft mods/ /server/mods/
COPY --chown=minecraft:minecraft docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /server/run.sh \
 && mkdir -p /server/world /server/logs /server/crash-reports /server/config /server/defaultconfigs \
 && chown -R minecraft:minecraft /server

USER minecraft

EXPOSE 25565 25575

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
