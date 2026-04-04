import 'package:test/test.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_parser.dart';
import 'package:funeralface_mobile/core/family_share_token.dart';

void main() {
  test('generated token is accepted by family deeplink parser', () {
    final token = generateFamilyShareToken();
    final uri = Uri.parse('https://links.funeralface.app/family/$token');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.funeralface.app'), token);
  });
}
