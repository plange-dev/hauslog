# Hauslog-Server: PocketBase mit dem Hauslog-Schema.
# Läuft auf x86-64 (NAS, PC, Cloud) und ARM (Raspberry Pi 3/4/5).
FROM alpine:3.22

ARG PB_VERSION=0.40.5
ARG TARGETARCH

RUN apk add --no-cache ca-certificates unzip wget \
 && case "$TARGETARCH" in arm) PB_ARCH=armv7 ;; *) PB_ARCH="$TARGETARCH" ;; esac \
 && wget -q -O /tmp/pb.zip \
      "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${PB_ARCH}.zip" \
 && unzip /tmp/pb.zip pocketbase -d /pb \
 && rm /tmp/pb.zip

COPY pb_migrations /pb/pb_migrations

EXPOSE 8090
VOLUME /pb/pb_data

# pb_public (optional, per Volume): dort abgelegt wird die Web-Version von
# Hauslog unter derselben Adresse ausgeliefert.
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090", \
     "--dir=/pb/pb_data", "--migrationsDir=/pb/pb_migrations", \
     "--publicDir=/pb/pb_public"]
