# Headless Ubuntu Web UI (Experimental)

If you run Libation on a headless Ubuntu server, you can keep the existing Avalonia desktop backend/UI and expose it in a browser using a virtual X display + noVNC.

> [!WARNING]
> This is an experimental setup. The standard/supported server path is still `LibationCli`.

## What changed

This mode adds a lightweight browser-access layer around the existing desktop build:

- `Docker/webui/Dockerfile` publishes `LibationAvalonia` and installs `Xvfb`, `fluxbox`, `x11vnc`, `noVNC`, and `websockify`.
- `Docker/webui/start-webui.sh` starts the virtual desktop stack and then launches Libation.
- `Docker/docker-compose.webui.yml` gives a one-command startup path for headless Ubuntu hosts.

No Libation business logic is rewritten—the same desktop app is rendered remotely in the browser.

## 1) Start the web UI container

From the repository root:

```bash
cd Docker
sudo docker compose -f docker-compose.webui.yml up -d --build
```

This exposes:

- `http://<server-ip>:6080/vnc.html`

## 2) Connect from your browser

Open:

```text
http://<server-ip>:6080/vnc.html?autoconnect=true&resize=remote
```

You should see the Libation desktop UI in the browser.

## Optional security: VNC password

Set `WEBUI_VNC_PASSWORD` in `docker-compose.webui.yml` (or your own env file) and redeploy:

```yaml
environment:
  - WEBUI_VNC_PASSWORD=change-me
```

With a password set, the noVNC client prompts for it before connecting.

## Volumes

The compose file mounts:

- `./config:/config`
- `./books:/data`

Use those host folders to persist Libation state and downloaded books.

## Best way to test this end-to-end

1. **Build and start the service**
   ```bash
   cd Docker
   sudo docker compose -f docker-compose.webui.yml up -d --build
   ```
2. **Check container health/logs**
   ```bash
   sudo docker compose -f docker-compose.webui.yml ps
   sudo docker logs libation-webui --tail 100
   ```
3. **Verify noVNC endpoint from server shell**
   ```bash
   curl -I http://127.0.0.1:6080/vnc.html
   ```
   Expected: `HTTP/1.1 200 OK`.
4. **Browser verification**
   - Open `http://<server-ip>:6080/vnc.html?autoconnect=true&resize=remote`.
   - Confirm Libation window appears.
5. **Persistence verification**
   - Make a visible settings change in Libation.
   - Restart container:
     ```bash
     sudo docker compose -f docker-compose.webui.yml restart
     ```
   - Confirm settings/data persist under `Docker/config` and downloads under `Docker/books`.

## Notes

- This approach is useful when you need full parity with the desktop interface on a headless server.
- For fully unattended scheduled operation, continue to prefer the existing Docker/CLI workflow.
