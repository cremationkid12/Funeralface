import 'package:flutter/services.dart';

/// Android product flavors: `dev` and `prod` (see `android/app/build.gradle.kts`).
/// Matches `--flavor`; also available as [appFlavor] from `package:flutter/services.dart`.
enum AppFlavor {
  dev,
  prod,
}

AppFlavor parseAppFlavor() {
  switch (appFlavor) {
    case 'dev':
      return AppFlavor.dev;
    case 'prod':
      return AppFlavor.prod;
    default:
      return AppFlavor.prod;
  }
}
