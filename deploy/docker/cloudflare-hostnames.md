# Cloudflare Tunnel Hostname Mapping

Add these public hostnames to the same Cloudflare Zero Trust tunnel:

- `myknitlog.hyeonseok.uk` -> `http://localhost:8791`
- `berrymix.hyeonseok.uk` -> `http://localhost:8792`
- `worldcreator.hyeonseok.uk` -> `http://localhost:8793`

Recommended settings:

- Type: `HTTP`
- TLS verify to origin: off only if Cloudflare asks for it for local plain HTTP origins
- WebSocket support: default on

After adding all three hostnames, load the launch agent plist:

```bash
mkdir -p ~/Library/LaunchAgents
cp deploy/docker/com.claw-empire.tunnel.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.claw-empire.tunnel.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.claw-empire.tunnel.plist
```

To inspect logs:

```bash
tail -f logs/cloudflared-tunnel.log logs/cloudflared-tunnel.error.log
```