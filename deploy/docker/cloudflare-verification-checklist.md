# Cloudflare Verification Checklist

Use this after configuring Public Hostnames in Cloudflare Zero Trust.

## 1. Fix the current origin protocol

Your current tunnel is receiving these mappings from Cloudflare:

- `myknitlog.hyeonseok.uk` -> `https://localhost:8791`
- `berrymix.hyeonseok.uk` -> `https://localhost:8792`
- `worldcreator.hyeonseok.uk` -> `https://localhost:8793`

The Claw-Empire containers are plain HTTP origins, so each of these must be changed to:

- `myknitlog.hyeonseok.uk` -> `http://localhost:8791`
- `berrymix.hyeonseok.uk` -> `http://localhost:8792`
- `worldcreator.hyeonseok.uk` -> `http://localhost:8793`

If the origin remains `https://localhost:*`, Cloudflare returns `502`.

## 2. Public Hostname settings

For each hostname in the Zero Trust dashboard:

- Type: `HTTP`
- URL: `localhost`
- Port: company port (`8791`, `8792`, `8793`)
- Additional settings: leave default unless you need Access policies

## 3. Local tunnel checks

Confirm the tunnel launch agent is loaded:

```bash
launchctl list | grep com.claw-empire.tunnel
```

Confirm the local process is running:

```bash
ps aux | grep '[c]loudflared'
```

Read the tunnel logs:

```bash
tail -f logs/cloudflared-tunnel.log logs/cloudflared-tunnel.error.log
```

You want to see:

- `Registered tunnel connection`
- no origin TLS errors
- Cloudflare configuration showing `http://localhost:8791` style origins

## 4. Local app checks

```bash
curl http://127.0.0.1:8791/healthz
curl http://127.0.0.1:8792/healthz
curl http://127.0.0.1:8793/healthz
```

Expected: each returns `{"ok":true,...}`.

## 5. Public hostname checks

```bash
curl -I https://myknitlog.hyeonseok.uk
curl -I https://berrymix.hyeonseok.uk
curl -I https://worldcreator.hyeonseok.uk
```

Expected:

- `HTTP/2 200` or a redirect to the app route
- not `502`
- not `1033` or `404` from tunnel mismatch

## 6. Browser checks

Open each hostname in a browser and verify:

- initial app shell loads
- WebSocket-driven updates still work
- task board and office screen open normally

## 7. If it still fails

- `502`: origin protocol or port mismatch, or local app not reachable
- `404`: missing fallback hostname rule or wrong hostname in Cloudflare dashboard
- `1033`: tunnel routing not attached to this hostname
- blank page with app errors: browser console/network tab next
