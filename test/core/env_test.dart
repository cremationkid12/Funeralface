import 'package:flutter_test/flutter_test.dart';
import 'package:funeralface_mobile/core/env.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppDotenv();
  });

  test('default env values are available', () {
    expect(AppEnv.apiBaseUrl, isNotEmpty);
    expect(AppEnv.appEnv, isNotEmpty);
    expect(AppEnv.deeplinkHost, isNotEmpty);
    expect(AppEnv.familyLinkBaseUrl, isNotEmpty);
    expect(['dev', 'staging', 'prod'], contains(AppEnv.flavor));
  });
}
