import 'package:test/test.dart';
import 'package:funeralface_mobile/core/env.dart';

void main() {
  test('default env values are available', () {
    expect(AppEnv.apiBaseUrl, isNotEmpty);
    expect(AppEnv.appEnv, isNotEmpty);
    expect(AppEnv.deeplinkHost, isNotEmpty);
    expect(AppEnv.familyLinkBaseUrl, isNotEmpty);
    expect(AppEnv.flavor, equals('dev'));
  });
}
