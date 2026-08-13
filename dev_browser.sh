#!/usr/bin/env bash

set -e

IMAGE="ghcr.io/calcite/devcontainer_browser:latest"

COMMON_ARGS=(
  --rm
  -it
  --name chromium4devcontainer
  -p 0.0.0.0:9223:9223
  --cap-add=SYS_ADMIN
  --shm-size=1g
)

# GPU support
if [ -e /dev/dri/renderD128 ]; then
  COMMON_ARGS+=(
    --device /dev/dri:/dev/dri
    --group-add "$(stat -c '%g' /dev/dri/renderD128)"
  )
fi

#
# Prefer native Wayland when available.
#
if [ -n "${WAYLAND_DISPLAY:-}" ] &&
   [ -n "${XDG_RUNTIME_DIR:-}" ] &&
   [ -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; then

  echo "Starting Chromium using Wayland"

  docker run "${COMMON_ARGS[@]}" \
    -e OZONE_PLATFORM=wayland \
    -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    -e XDG_RUNTIME_DIR=/tmp/xdg-runtime \
    --mount \
      type=bind,src="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY",dst="/tmp/xdg-runtime/$WAYLAND_DISPLAY" \
    "$IMAGE"

#
# Fall back to X11.
#
elif [ -n "${DISPLAY:-}" ]; then

  echo "Starting Chromium using X11"

  X11_ARGS=(
    -e OZONE_PLATFORM=x11
    -e DISPLAY="$DISPLAY"
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw
  )

  # Pass X11 authentication cookie when available.
  if [ -n "${XAUTHORITY:-}" ] && [ -f "$XAUTHORITY" ]; then
    X11_ARGS+=(
      -e XAUTHORITY=/tmp/.Xauthority
      -v "$XAUTHORITY:/tmp/.Xauthority:ro"
    )
  elif [ -f "$HOME/.Xauthority" ]; then
    X11_ARGS+=(
      -e XAUTHORITY=/tmp/.Xauthority
      -v "$HOME/.Xauthority:/tmp/.Xauthority:ro"
    )
  fi

  docker run "${COMMON_ARGS[@]}" \
    "${X11_ARGS[@]}" \
    "$IMAGE"

else
  echo "Neither Wayland nor X11 display was detected."
  exit 1
fi
