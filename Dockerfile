FROM docker:stable-dind

ARG SUPERCRONIC_ARCH="amd64"
ARG SUPERCRONIC_REPO="aptible/supercronic"
ARG DOCKER_COMPOSE_ARCH="x86_64"
ARG DOCKER_COMPOSE_REPO="docker/compose"
ARG ALPINE_GLIBC_PACKAGE_VERSION="2.28-r0"
ARG ALPINE_GLIBC_REPO="sgerrand/alpine-pkg-glibc"
ARG LANG=en_US.UTF-8

ENV TZ="Asia/Hong_Kong"

ENV SUPERCRONIC_PACKAGE="" \
    SUPERCRONIC_URL="" \
    SUPERCRONIC_REPO_JSON="" \
    SUPERCRONIC_VERSION="" \
    DOCKER_COMPOSE_URL="" \
    DOCKER_COMPOSE_REPO_JSON="" \
    DOCKER_COMPOSE_VERSION="" \
    DOCKER_COMPOSE_PACKAGE="" \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk"

COPY ./locale.txt /tmp/locale.txt
COPY ./apk-packages.txt /tmp/apk-packages.txt
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN echo "Installing Global Dependencies" && \
    apk add --update --no-cache $(cat "/tmp/apk-packages.txt" | tr '\n' ' ') && \
    chmod +x /docker-entrypoint.sh

# install supercronic
RUN echo "Installing Build Dependencies" && \
    apk add --no-cache -t .supercronic ca-certificates curl sed && \
    echo "Finding Latest Supercronic Version..." && \
    SUPERCRONIC_REPO_JSON=`curl -s "https://api.github.com/repos/$SUPERCRONIC_REPO/releases/latest" | jq -c '.assets[] | select(.name | contains("'$SUPERCRONIC_ARCH'"))'` && \
    SUPERCRONIC_URL=`echo "$SUPERCRONIC_REPO_JSON" | jq -r '.browser_download_url'` && \
    SUPERCRONIC_PACKAGE=`echo "$SUPERCRONIC_REPO_JSON" | jq -r '.name'` && \
    SUPERCRONIC_VERSION=`echo "$SUPERCRONIC_URL" | sed -n 's/.*\/v\([0-9.]*\)\/.*/\1/p'` && \
    echo "Downloading ${SUPERCRONIC_PACKAGE} v${SUPERCRONIC_VERSION}..." && \
    curl -fsSLo "/bin/${SUPERCRONIC_PACKAGE}" "$SUPERCRONIC_URL"  && \
    chmod +x "/bin/${SUPERCRONIC_PACKAGE}" && \
    ln -s "/bin/${SUPERCRONIC_PACKAGE}" /bin/supercronic

# Install glibc (required for docker-compose)
RUN echo "Downloading glibc (docker-compose dependency)..." && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    curl -fsSLO "https://github.com/${ALPINE_GLIBC_REPO}/releases/download/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" && \
    curl -fsSLO "https://github.com/${ALPINE_GLIBC_REPO}/releases/download/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" && \
    curl -fsSLO "https://github.com/${ALPINE_GLIBC_REPO}/releases/download/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    echo "Installing glibc $ALPINE_GLIBC_PACKAGE_VERSION" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    cat "/tmp/locale.txt" | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8 && \
    #/usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG; export LANGUAGE=$LANG" > /etc/profile.d/locale.sh

RUN echo "Finding Latest Docker Compose Version..." && \
    DOCKER_COMPOSE_REPO_JSON=`curl -s "https://api.github.com/repos/$DOCKER_COMPOSE_REPO/releases/latest" | jq -c '.assets[] | select(.name == "docker-compose-Linux-'$DOCKER_COMPOSE_ARCH'")'` && \
    DOCKER_COMPOSE_URL=`echo "$DOCKER_COMPOSE_REPO_JSON" | jq -r '.browser_download_url'` && \
    DOCKER_COMPOSE_PACKAGE=`echo "$DOCKER_COMPOSE_REPO_JSON" | jq -r '.name'` && \
    echo "Downloading Docker Compose..." && \
    curl -fsSLo "/bin/${DOCKER_COMPOSE_PACKAGE}" "$DOCKER_COMPOSE_URL"  && \
    chmod +x "/bin/${DOCKER_COMPOSE_PACKAGE}" && \
    ln -s "/bin/${DOCKER_COMPOSE_PACKAGE}" /bin/docker-compose && \
    echo "Docker Compose Version" && \
    docker-compose version

# Clean up
RUN echo "Cleaning Up..." && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" \
       "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk del --no-cache --purge .supercronic glibc-i18n && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

VOLUME ["/etc/crontabs"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/supercronic", "/etc/crontabs/crontab"]
