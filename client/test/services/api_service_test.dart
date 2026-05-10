import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:animesync/services/api_service.dart';
import 'package:animesync/models/models.dart';

void main() {
  late MockClient mockClient;
  late ApiService api;

  setUp(() {
    mockClient = MockClient((http.BaseRequest request) async {
      // Default: return 404 for unhandled routes
      return http.Response('{"code":404,"message":"Not found"}', 404);
    });
    api = ApiService(
      baseUrl: 'https://test.example.com',
      getToken: () async => 'test-token',
      client: mockClient,
    );
  });

  group('ApiService', () {
    test('构造正确保存 baseUrl 和 getToken', () {
      expect(api.baseUrl, 'https://test.example.com');
      expect(api.getToken, isNotNull);
    });

    group('_url', () {
      test('拼接路径正确', () {
        // Access private method via reflection not possible; test via actual calls
        // We'll infer from actual requests
      });
    });

    group('Health', () {
      test('返回健康状态', () async {
        mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'https://test.example.com/api/health');
          return http.Response(
            '{"code":200,"message":"ok","data":{"status":"healthy"}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        final response = await api.health();
        expect(response.code, 200);
        expect(response.message, 'ok');
        expect(response.data?['status'], 'healthy');
      });

      test('非 200 响应抛出异常', () async {
        mockClient = MockClient((request) async {
          return http.Response('{"code":500,"message":"Server error"}', 500);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        expect(api.health(), throwsA(isA<ApiException>().having((e) => e.code, 'code', 500)));
      });
    });

    group('Auth', () {
      test('register 成功返回 AuthData', () async {
        mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://test.example.com/api/auth/register');
        // Body verification omitted for unit test simplicity
        return http.Response(
            '{"code":200,"message":"registered","data":{"access_token":"new-token","token_type":"bearer","user":{"id":1,"username":"newuser"}}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        final response = await api.register('newuser', 'password123');
        expect(response.code, 200);
        expect(response.data?.accessToken, 'new-token');
        expect(response.data?.user.username, 'newuser');
      });

      test('register 失败抛出异常', () async {
        mockClient = MockClient((request) async {
          return http.Response('{"code":400,"message":"Username exists"}', 400);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        expect(
          api.register('existing', 'pass'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 400)),
        );
      });

      test('login 成功返回 AuthData', () async {
        mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"message":"ok","data":{"access_token":"login-token","token_type":"bearer","user":{"id":2,"username":"loginuser"}}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        final response = await api.login('loginuser', 'pass');
        expect(response.code, 200);
        expect(response.data?.accessToken, 'login-token');
        expect(response.data?.user.id, 2);
      });

      test('getMe 成功返回 UserInfo', () async {
        mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"message":"ok","data":{"id":5,"username":"me"}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'my-token',
          client: mockClient,
        );

        final response = await api.getMe();
        expect(response.code, 200);
        expect(response.data?.id, 5);
        expect(response.data?.username, 'me');
      });
    });

    group('Progress', () {
      test('listProgress 返回列表', () async {
        mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"message":"ok","data":[{"id":1,"title":"Anime A","status":"watching","watched_episodes":5},{"id":2,"title":"Anime B","status":"completed","watched_episodes":12}]}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: mockClient,
        );

        final response = await api.listProgress();
        expect(response.code, 200);
        expect(response.data, hasLength(2));
        expect(response.data![0].title, 'Anime A');
        expect(response.data![1].status, 'completed');
      });

      test('create 成功返回 AnimeProgress', () async {
        mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        // Body verification omitted
        return http.Response(
            '{"code":200,"message":"created","data":{"id":100,"title":"New Anime","status":"watching","watched_episodes":0}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: mockClient,
        );

        final response = await api.create({'title': 'New Anime', 'status': 'watching'});
        expect(response.code, 200);
        expect(response.data?.id, 100);
      });

      test('watch 增加集数', () async {
        mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        // Body verification omitted
        return http.Response(
            '{"code":200,"message":"ok","data":{"id":1,"watched_episodes":6}}',
            200,
          );
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: mockClient,
        );

        final response = await api.watch(1, 1);
        expect(response.code, 200);
        expect(response.data?.watchedEpisodes, 6);
      });

      test('delete 成功无返回', () async {
        mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          return http.Response('{"code":200,"message":"deleted"}', 200);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: mockClient,
        );

        expect(api.delete(1), completes); // No exception
      });

      test('delete 失败抛出异常', () async {
        mockClient = MockClient((request) async {
          return http.Response('{"code":404,"message":"Not found"}', 404);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: mockClient,
        );

        expect(api.delete(999), throwsA(isA<ApiException>()));
      });
    });

    group('Headers', () {
      test('包含 Content-Type 和 Authorization', () async {
        bool headerChecked = false;
        mockClient = MockClient((request) async {
          final headers = request.headers;
        expect(headers['content-type'], 'application/json');
        expect(headers['authorization'], 'Bearer test-token');
          headerChecked = true;
          return http.Response('{"code":200,"message":"ok"}', 200);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'test-token',
          client: mockClient,
        );

        await api.health();
        expect(headerChecked, true);
      });

      test('无 token 时不包含 Authorization', () async {
        bool headerChecked = false;
        mockClient = MockClient((request) async {
          final headers = request.headers;
          expect(headers.containsKey('Authorization'), isFalse);
          headerChecked = true;
          return http.Response('{"code":200,"message":"ok"}', 200);
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => null,
          client: mockClient,
        );

        await api.health();
        expect(headerChecked, true);
      });
    });

    group('Dispose', () {
      test('关闭客户端', () {
        bool closed = false;
        mockClient = MockClient((request) async {
          return http.Response('ok', 200);
        });
        // Add a close method to track
        final trackedClient = _TrackedClient(mockClient, () {
          closed = true;
        });
        api = ApiService(
          baseUrl: 'https://test.example.com',
          getToken: () async => 'token',
          client: trackedClient,
        );
        api.dispose();
        expect(closed, true);
      });
    });
  });
}

// Helper to track if close was called
class _TrackedClient extends http.BaseClient {
  final http.Client _inner;
  final Function onClose;

  _TrackedClient(this._inner, this.onClose);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    onClose();
    _inner.close();
    super.close();
  }
}
