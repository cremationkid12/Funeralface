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

## Family status links (browser only)

Families view assignment status on the **website**, not inside the staff app.

- Staff create/copy/email links from the expanded assignment card (`FAMILY_LINK_BASE` + `/family/<token>` via `AppEnv.familyShareUrlForToken`).
- Set **`FAMILY_LINK_BASE`** in `.env` to your deployed web app origin (e.g. `https://everroutefuneral.com`). Override with `--dart-define=FAMILY_LINK_BASE=...` in CI if needed.
- The mobile app does **not** register Android App Links or iOS Universal Links for family URLs.
