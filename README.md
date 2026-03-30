# funeralface_mobile

Funeralface mobile app (Flutter).

## Environment (compile-time)

Flutter reads config via `--dart-define` (see `lib/core/env.dart`). Example:

```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8010 --dart-define=APP_ENV=development --dart-define=DEV_AUTH_BEARER_TOKEN=<jwt>
```

On **Android**, `dev`, `staging`, and `prod` product flavors are defined (P4.1). Pass `--flavor` for `flutter run` / `flutter build apk`. Use `prod` for release-style builds (no application id suffix). **iOS** does not mirror flavors yet; use the same `--dart-define` values.

For a physical device, use your machine LAN IP instead of `localhost`.

Copy `.env.example` to `.env` for local reference only; Dart does not load `.env` files unless you add a code generator.

## App structure

- **Routing:** `go_router` with a `StatefulShellRoute` tab shell (`lib/app/router/app_router.dart`, `lib/shell/main_shell.dart`).
- **DI:** `provider` + `AppRepositories` (`lib/app/app_repositories.dart`).
- **Staff tabs:** Dashboard, Assignments, Staff, Settings under `lib/features/`.
