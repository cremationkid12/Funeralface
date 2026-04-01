import 'package:test/test.dart';
import 'package:funeralface_mobile/core/deeplink/deeplink_parser.dart';

void main() {
  test('extracts token from /family/<token> path', () {
    final uri = Uri.parse('https://links.example.com/family/abc-token-123');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), 'abc-token-123');
  });

  test('returns null when host does not match expectedHost', () {
    final uri = Uri.parse('https://evil.example.com/family/abc-token-123');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), isNull);
  });

  test('extracts token from query parameter', () {
    final uri = Uri.parse('https://links.example.com/open?token=xyz');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), isNull);
  });

  test('extracts token from query parameter when explicitly enabled', () {
    final uri = Uri.parse('https://links.example.com/open?token=xyz123');
    expect(
      extractFamilyAssignmentToken(
        uri,
        expectedHost: 'links.example.com',
        allowQueryFallback: true,
      ),
      'xyz123',
    );
  });

  test('path token wins over query when both present', () {
    final uri = Uri.parse('https://links.example.com/family/path-token?q=1&token=query-token');
    expect(
      extractFamilyAssignmentToken(
        uri,
        expectedHost: 'links.example.com',
        allowQueryFallback: true,
      ),
      'path-token',
    );
  });

  test('rejects extra path segments', () {
    final uri = Uri.parse('https://links.example.com/family/abc-token-123/extra');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), isNull);
  });

  test('rejects suspicious token characters', () {
    final uri = Uri.parse('https://links.example.com/family/../../etc/passwd');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), isNull);
  });

  test('rejects too short token', () {
    final uri = Uri.parse('https://links.example.com/family/abc');
    expect(extractFamilyAssignmentToken(uri, expectedHost: 'links.example.com'), isNull);
  });
}
