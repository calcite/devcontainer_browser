#!/bin/bash
docker run --rm \
  --name devcontainer_browser \
  -p 127.0.0.1:9223:9223 \
  --cap-add=SYS_ADMIN \
  --shm-size=1g \
  --group-add "$(stat -c '%g' /dev/dri/renderD128)" \
  --device /dev/dri:/dev/dri \
  -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  -e XDG_RUNTIME_DIR=/tmp/xdg-runtime \
  --mount type=bind,src="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY",dst="/tmp/xdg-runtime/$WAYLAND_DISPLAY" \
  ghcr.io/calcite/devcontainer_browser:latest

