# syntax=docker/dockerfile:1

FROM debian:trixie-slim

ARG UID=1000
ARG GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium \
        chromium-sandbox \
        nginx \
        ca-certificates \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# UID/GID je vhodné mít stejné jako uživatel na hostu,
# protože Wayland socket je chráněný unixovými právy.
RUN groupadd --gid "${GID}" browser \
    && useradd \
        --uid "${UID}" \
        --gid "${GID}" \
        --create-home \
        --shell /bin/sh \
        browser \
    && mkdir -p \
        /data/browser-profile \
        /tmp/xdg-runtime \
    && chown -R browser:browser \
        /data \
        /tmp/xdg-runtime

COPY <<"EOF" /etc/nginx/nginx.conf
worker_processes 1;
pid /tmp/nginx-1000.pid;
error_log stderr error;

events {
    worker_connections 32;
}

http {
    access_log off;

    client_body_temp_path /tmp/nginx-client-body;
    proxy_temp_path       /tmp/nginx-proxy;
    fastcgi_temp_path     /tmp/nginx-fastcgi;
    uwsgi_temp_path       /tmp/nginx-uwsgi;
    scgi_temp_path        /tmp/nginx-scgi;

    server {
        listen 0.0.0.0:9223;

        location / {
            proxy_pass http://127.0.0.1:9222;
            proxy_http_version 1.1;

            # Ponecháme původní Host. Pro localhost/IP tak Chromium
            # vrací websocketDebuggerUrl rovnou s portem 9223.
            proxy_set_header Host $http_host;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_buffering off;
        }
    }
}
EOF

COPY <<"EOF" /usr/local/bin/start-browser
#!/bin/sh

set -u

cleanup() {
    if [ -f /tmp/nginx-1000.pid ]; then
        kill -QUIT "$(cat /tmp/nginx-1000.pid)" 2>/dev/null || true
    fi
}

trap cleanup EXIT

nginx -c /etc/nginx/nginx.conf

chromium \
    --ozone-platform="${OZONE_PLATFORM:-wayland}" \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port=9222 \
    --user-data-dir=/data/browser-profile \
    --password-store=basic \
    "$@"

exit $?
EOF

RUN chmod +x /usr/local/bin/start-browser

USER browser

ENV XDG_RUNTIME_DIR=/tmp/xdg-runtime
ENV WAYLAND_DISPLAY=wayland-0

EXPOSE 9223

ENTRYPOINT ["/usr/local/bin/start-browser"]