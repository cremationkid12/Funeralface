# funeralface_mobile

Funeralface mobile app (Flutter).

## Environment

Runtime values come from **`flutter_dotenv`**: on startup the app loads project-root **`.env`** (bundled as a Flutter asset) and then **`assets/env.default`** for any keys you omit. Copy `.env.example` to `.env` next to `pubspec.yaml` before your first `flutter run` / `flutter build` — the `.env` path is listed under `flutter: assets:` and the file must exist so the asset bundle step succeeds.

Non-empty **`--dart-define=...`** entries still override the same keys (useful in CI without checking in secrets).

On **Android**, the app now uses a single default variant (no product flavors), so you can run with plain `flutter run` / `flutter build apk`.

For a physical device, use your machine LAN IP instead of `localhost` in `.env` where applicable.

## App structure

- **Routing:** `go_router` with a `StatefulShellRoute` tab shell (`lib/app/router/app_router.dart`, `lib/shell/main_shell.dart`).
- **DI:** `provider` + `AppRepositories` (`lib/app/app_repositories.dart`).
- **Staff tabs:** Dashboard, Assignments, Staff, Settings under `lib/features/`.

## Family deep links (P5 / P6.5)

- In-app path: **`/family/<token>`** (see `FamilyAssignmentScreen` and `extractFamilyAssignmentToken` in `lib/core/deeplink/deeplink_parser.dart`).
- Parser is strict by default: exact host match (when configured), only `/family/<token>`, and token-format validation; legacy `?token=` fallback is opt-in (`allowQueryFallback: true`).
- **Android:** `AndroidManifest.xml` includes a `VIEW` intent-filter with `https`, host **`links.everroute.app`**, and `pathPrefix` **`/family/`**. Replace that host with your verified domain and complete [Digital Asset Links](https://developer.android.com/training/app-links) before production.
- **iOS:** `Runner.entitlements` now includes Associated Domains scaffold for `applinks:links.everroute.app`. Replace host and publish `apple-app-site-association` before production.
- Runtime link ingestion is wired through `app_links` in `main.dart` and routes matching links to `/family/<token>` only.
- **Staff copy URL:** `FAMILY_LINK_BASE` (default `https://links.everroute.app`) is used on the assignment detail screen when generating/copying a family link so the clipboard matches your verified host. Override with `--dart-define=FAMILY_LINK_BASE=https://your-staging-host.example` when testing.

Manual check: run the app with `flutter run`, then open
`http://localhost:<port>/family/<token>` is not available from the browser; use `adb shell am start -a android.intent.action.VIEW -d "https://links.everroute.app/family/<token>"` after updating the host to match your manifest.
