FROM pyunramura/alpine-s6:3.8

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.vcs-url="$VCS_URL" \
      org.label-schema.version="$VERSION" \
      org.label-schema.maintainer="pyunramura"

# The versions are pinned for stable,
# reproducible, deterministic, pure builds.
RUN \
    echo "---- installing packages ----" && \
    apk add --no-cache \
            openvpn=2.4.6-r3

HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
            CMD curl -L 'https://api.ipify.org'

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
