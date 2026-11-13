# syntax=docker/dockerfile:1

# Radarr v6 on the shared Alpine base, rootless from the first process.
# Upstream ships a self-contained .NET build (runtime inside the tarball), so
# the image only adds the native libraries that runtime loads.
FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:73a14e80b779043678834af2c47d6c1c17dc1982733d596fba38bafd1093e5b5 AS fetch
ARG VERSION="6.4.4.10685"
ARG BRANCH="master"
RUN apk add --no-cache curl \
    && mkdir -p /out/bin \
    && curl -fsSL -o /tmp/app.tgz \
        "https://radarr.servarr.com/v1/update/${BRANCH}/updatefile?version=${VERSION}&os=linuxmusl&runtime=netcore&arch=x64" \
    && tar -xzf /tmp/app.tgz -C /out/bin --strip-components=1 \
    && rm -rf /out/bin/Radarr.Update /tmp/app.tgz \
    && printf 'UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[Rake-Pro](https://github.com/Rake-Pro)\n' "${BRANCH}" "${VERSION}" > /out/package_info \
    && chmod -R u=rwX,go=rX /out

FROM ghcr.io/rake-pro/alpine-base:1.0@sha256:73a14e80b779043678834af2c47d6c1c17dc1982733d596fba38bafd1093e5b5
ARG VERSION
LABEL org.opencontainers.image.source="https://github.com/Rake-Pro/radarr" \
      org.opencontainers.image.version="${VERSION}"

# PGGSSENCMODE: krb5 on musl is not thread-safe and Npgsql's GSS probe
# segfaults on it (exit 139) when a PostgreSQL backend is configured.
ENV HOME="/config" \
    DOTNET_EnableDiagnostics=0 \
    PGGSSENCMODE=disable \
    RADARR__UPDATE__BRANCH=master

RUN apk add --no-cache \
        icu-libs \
        krb5-libs \
        libintl \
        sqlite-libs

COPY --from=fetch /out /app
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

USER 65534:65534
WORKDIR /config
VOLUME ["/config"]
EXPOSE 7878

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
