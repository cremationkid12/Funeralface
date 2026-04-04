# funeralface_mobile

Funeralface mobile app (Flutter).

## Environment (compile-time)

Flutter reads config via `--dart-define` (see `lib/core/env.dart`). Example:

```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8010 --dart-define=APP_ENV=development
```

Supabase auth mode (register/login pages + session restore):

```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8010 --dart-define=APP_ENV=development --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

**Important:** There must be a **space** before each `--dart-define`. If you paste flags back-to-back (for example `...supabase.co--dart-define=SUPABASE_ANON_KEY=...`), Flutter treats the URL as one long invalid value and **Supabase auth is disabled**, so the app will not redirect to `/auth` and Register/Login will not appear.

On **Android**, `dev`, `staging`, and `prod` product flavors are defined (P4.1). Pass `--flavor` for `flutter run` / `flutter build apk`. Use `prod` for release-style builds (no application id suffix). **iOS** does not mirror flavors yet; use the same `--dart-define` values.

For a physical device, use your machine LAN IP instead of `localhost`.

Copy `.env.example` to `.env` for local reference only; Dart does not load `.env` files unless you add a code generator.

## App structure

- **Routing:** `go_router` with a `StatefulShellRoute` tab shell (`lib/app/router/app_router.dart`, `lib/shell/main_shell.dart`).
- **DI:** `provider` + `AppRepositories` (`lib/app/app_repositories.dart`).
- **Staff tabs:** Dashboard, Assignments, Staff, Settings under `lib/features/`.

## Family deep links (P5 / P6.5)

- In-app path: **`/family/<token>`** (see `FamilyAssignmentScreen` and `extractFamilyAssignmentToken` in `lib/core/deeplink/deeplink_parser.dart`).
- Parser is strict by default: exact host match (when configured), only `/family/<token>`, and token-format validation; legacy `?token=` fallback is opt-in (`allowQueryFallback: true`).
- **Android:** `AndroidManifest.xml` includes a `VIEW` intent-filter with `https`, host **`links.funeralface.app`**, and `pathPrefix` **`/family/`**. Replace that host with your verified domain and complete [Digital Asset Links](https://developer.android.com/training/app-links) before production.
- **iOS:** `Runner.entitlements` now includes Associated Domains scaffold for `applinks:links.funeralface.app`. Replace host and publish `apple-app-site-association` before production.
- Runtime link ingestion is wired through `app_links` in `main.dart` and routes matching links to `/family/<token>` only.
- **Staff copy URL:** `FAMILY_LINK_BASE` (default `https://links.funeralface.app`) is used on the assignment detail screen when generating/copying a family link so the clipboard matches your verified host. Override with `--dart-define=FAMILY_LINK_BASE=https://your-staging-host.example` when testing.

Manual check: `flutter run --flavor dev ...` then open
`http://localhost:<port>/family/<token>` is not available from the browser; use `adb shell am start -a android.intent.action.VIEW -d "https://links.funeralface.app/family/<token>"` after updating the host to match your manifest.
