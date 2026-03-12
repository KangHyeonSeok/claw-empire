# Cloudflare Access Guide For Company Subdomains

Use Cloudflare Access if you want each company UI protected by login before anyone reaches Claw-Empire.

## Recommended model

Protect each company subdomain with one Access application.

- `myknitlog.hyeonseok.uk`
- `berrymix.hyeonseok.uk`
- `worldcreator.hyeonseok.uk`

This keeps the company entry points separate while reusing the same tunnel.

## Access setup

In Cloudflare Zero Trust:

1. Go to `Access` -> `Applications`
2. Create a `Self-hosted` application
3. Application domain:
   - `myknitlog.hyeonseok.uk`
4. Session duration:
   - choose your policy, for example `24 hours`
5. Add an allow policy:
   - your email address
   - or your Google/GitHub identity provider group

Repeat for:

- `berrymix.hyeonseok.uk`
- `worldcreator.hyeonseok.uk`

## Suggested policy options

- Small personal team:
  - allow specific email addresses
- One-person operator:
  - allow only your Google account
- Shared internal use:
  - allow your identity provider group

## Notes for Claw-Empire

- The app uses HTTP plus WebSocket traffic; Cloudflare Access supports this model.
- No application code change is required if Access is enforced at the Cloudflare edge.
- If you later expose API endpoints separately, keep them behind the same protected hostname unless you intentionally want machine-to-machine access.

## Minimal recommended first policy

- Identity provider: Google or GitHub
- Allow: `KangHyeonSeok` account only
- No public bypass rules

## Post-setup tests

1. Open the company subdomain in a fresh private window
2. Confirm Access login appears first
3. Complete login
4. Confirm the app loads normally after authentication
5. Confirm reload works without an immediate new challenge during the session lifetime
