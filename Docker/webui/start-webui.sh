#!/usr/bin/env bash
set -euo pipefail

export DISPLAY="${DISPLAY:-:1}"
export HOME="${HOME:-/home/libation}"

mkdir -p "${LIBATION_HOME:-/config}" /tmp/.X11-unix

# Prefer the Avalonia executable, but allow override for troubleshooting.
APP_BIN="${LIBATION_EXECUTABLE:-/libation/LibationAvalonia}"
if [[ ! -x "$APP_BIN" ]]; then
  APP_BIN="$(find /libation -maxdepth 1 -type f -executable | head -n 1)"
fi

if [[ -z "${APP_BIN:-}" || ! -x "$APP_BIN" ]]; then
  echo "Unable to find a Libation executable in /libation" >&2
  exit 1
fi

# Optional VNC password support. If WEBUI_VNC_PASSWORD is set, require auth.
VNC_AUTH_ARGS=(-nopw)
if [[ -n "${WEBUI_VNC_PASSWORD:-}" ]]; then
  VNC_PASS_FILE="${HOME}/.vnc/passwd"
  mkdir -p "$(dirname "$VNC_PASS_FILE")"
  x11vnc -storepasswd "$WEBUI_VNC_PASSWORD" "$VNC_PASS_FILE" >/dev/null 2>&1
  chmod 600 "$VNC_PASS_FILE"
  VNC_AUTH_ARGS=(-rfbauth "$VNC_PASS_FILE")
fi

Xvfb "$DISPLAY" -screen 0 1920x1080x24 -nolisten tcp &
XVFB_PID=$!

fluxbox >/tmp/fluxbox.log 2>&1 &
FLUXBOX_PID=$!

x11vnc -display "$DISPLAY" -forever -shared -xkb -rfbport 5900 "${VNC_AUTH_ARGS[@]}" >/tmp/x11vnc.log 2>&1 &
X11VNC_PID=$!

websockify --web=/usr/share/novnc/ 0.0.0.0:6080 localhost:5900 >/tmp/websockify.log 2>&1 &
WEBSOCKIFY_PID=$!

cleanup() {
  kill "$WEBSOCKIFY_PID" "$X11VNC_PID" "$FLUXBOX_PID" "$XVFB_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

"$APP_BIN" "$@"
