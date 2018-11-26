FROM docker:stable-dind

ENV SUPERCRONIC_ARCH="amd64" \
    SUPERCRONIC_SHA1SUM=96960ba3207756bb01e6892c978264e5362e117e \
    SUPERCRONIC_REPO="aptible/supercronic" \
    SUPERCRONIC_PACKAGE="" \
    SUPERCRONIC_URL="" \
    SUPERCRONIC_REPO_JSON="" \
    SUPERCRONIC_VERSION=""

# install dependencies
RUN apk add --update --no-cache ca-certificates curl jq \
# install supercronic
  && echo "Finding Latest Supercronic Version..." \
  && SUPERCRONIC_REPO_JSON=`curl -s "https://api.github.com/repos/$SUPERCRONIC_REPO/releases/latest" | jq -c '.assets[] | select(.name | contains("'$SUPERCRONIC_ARCH'"))'` \
  && SUPERCRONIC_URL=`echo "$SUPERCRONIC_REPO_JSON" | jq -r '.browser_download_url'` \
  && SUPERCRONIC_PACKAGE=`echo "$SUPERCRONIC_REPO_JSON" | jq -r '.name'` \
  && SUPERCRONIC_VERSION=`echo "$SUPERCRONIC_URL" | sed -n 's/.*\/v\([0-9.]*\)\/.*/\1/p'` \
  && echo "Downloading ${SUPERCRONIC_PACKAGE} v${SUPERCRONIC_VERSION}..." \
  && curl -fsSLo "/bin/${SUPERCRONIC_PACKAGE}" "$SUPERCRONIC_URL"  \
  && chmod +x "/bin/${SUPERCRONIC_PACKAGE}" \
  && ln -s "/bin/${SUPERCRONIC_PACKAGE}" /bin/supercronic \
# remove unwanted deps & cleanup
  && apk del --no-cache --purge ca-certificates curl \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

VOLUME ["/etc/crontabs"]

ENTRYPOINT ["supercronic"]
CMD ["/etc/crontabs/crontab"]
