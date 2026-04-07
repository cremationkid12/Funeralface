import 'package:test/test.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getJson returns decoded body on success', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://localhost:8010/v1/health');
      return http.Response('{"status":"ok"}', 200);
    });

    final api = ApiClient(baseUrl: 'http://localhost:8010', httpClient: client);
    final json = await api.getJson('/v1/health');

    expect(json['status'], 'ok');
  });

  test('getJson throws ApiException on non-2xx', () async {
    final client = MockClient((_) async => http.Response('{"message":"bad"}', 400));
    final api = ApiClient(baseUrl: 'http://localhost:8010', httpClient: client);

    expect(
      () => api.getJson('/v1/health'),
      throwsA(isA<ApiException>()),
    );
  });

  test('postJson sends body and returns decoded payload', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.body, '{"name":"demo"}');
      return http.Response('{"id":"1"}', 201);
    });

    final api = ApiClient(baseUrl: 'http://localhost:8010', httpClient: client);
    final json = await api.postJson('/v1/staff', body: {'name': 'demo'});
    expect(json['id'], '1');
  });

  test('delete succeeds on 204', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      return http.Response('', 204);
    });

    final api = ApiClient(baseUrl: 'http://localhost:8010', httpClient: client);
    await api.delete('/v1/staff/1');
  });

  test('bare production host gets https scheme', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.example.com/v1/health',
      );
      return http.Response('{}', 200);
    });

    final api = ApiClient(baseUrl: 'api.example.com', httpClient: client);
    await api.getJson('/v1/health');
  });

  test('bare emulator loopback gets http scheme', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://10.0.2.2:8010/v1/health');
      return http.Response('{}', 200);
    });

    final api = ApiClient(baseUrl: '10.0.2.2:8010', httpClient: client);
    await api.getJson('/v1/health');
  });
}
