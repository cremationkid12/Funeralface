# funeralface_mobile

Funeralface mobile app (Flutter).

## Environment (compile-time)

Flutter reads config via `--dart-define` (see `lib/core/env.dart`). Example:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010 --dart-define=APP_ENV=development
```

For a physical device, use your machine LAN IP instead of `localhost`.

Copy `.env.example` to `.env` for local reference only; Dart does not load `.env` files unless you add a code generator.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
