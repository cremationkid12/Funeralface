# P5.1 Deep Link Verification Checklist

Use this checklist before marking P5.1 complete.

## 1) Domain and host alignment

- Choose one canonical host (example: `links.funeralface.app`).
- Set `DEEPLINK_HOST` in mobile build/run defines when needed.
- Ensure Android manifest placeholder `DEEPLINK_HOST` resolves to the same value.
- Ensure iOS entitlements Associated Domains host matches exactly.

## 2) Android App Links

- Publish `https://<host>/.well-known/assetlinks.json`.
- Include all signing cert SHA-256 fingerprints for build variants you test.
- Verify with:
  - `adb shell pm get-app-links <applicationId>`
  - tap/open `https://<host>/family/<token>`
- Confirm app opens directly (cold/warm).

Template file in this repo:
- `doc/templates/assetlinks.json.example`

## 3) iOS Universal Links

- Publish `https://<host>/.well-known/apple-app-site-association` (no `.json` extension).
- Confirm `Runner.entitlements` has `applinks:<host>`.
- Reinstall app on device after entitlement/domain changes.
- Verify by opening `https://<host>/family/<token>` from Notes/Safari.

Template file in this repo:
- `doc/templates/apple-app-site-association.example`

## 4) Security behavior checks

- Valid link path `/family/<token>` opens app and routes to family status screen.
- Unknown host must not route inside app.
- Wrong path (not `/family/...`) must not route inside app.
- Malformed token must be rejected safely.
- Expired/revoked token must show safe error state.

## 5) Release gate evidence

- Capture screenshots/logs for:
  - Android cold start
  - Android warm start
  - iOS cold start
  - iOS warm start
- Attach verification artifacts to the phase/PR notes before closing P5.1.
