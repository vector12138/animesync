import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final Future<String?> Function() getToken;
  final Future<String?> Function()? getRefreshToken;
  final void Function(String accessToken, String refreshToken)? onTokensUpdated;
  final http.Client _client;

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  ApiService({
    required this.baseUrl,
    required this.getToken,
    this.getRefreshToken,
    this.onTokensUpdated,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String _url(String path) => '$baseUrl$path';

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── 统一请求包装：自动刷新 401 ──
  Future<ApiResponse<T>> _executeWithAuthRefresh<T>(
    Future<ApiResponse<T>> Function() request,
  ) async {
    try {
      return await request();
    } on ApiException catch (e) {
      if (e.code == 401) {
        await _tryRefresh();
        return await request(); // 重试一次
      }
      rethrow;
    }
  }

  Future<void> _tryRefresh() async {
    // 如果已经在刷新，等待完成即可
    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await getRefreshToken?.call();
      if (refreshToken == null) {
        throw ApiException(401, 'No refresh token available');
      }

      final r = await _client.post(
        Uri.parse(_url('/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (r.statusCode != 200) {
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        throw ApiException(r.statusCode, json['detail']?.toString() ?? 'Refresh failed');
      }

      final json = jsonDecode(r.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      // 回调更新本地存储
      if (onTokensUpdated != null) {
        await onTokensUpdated!(newAccessToken, newRefreshToken);
      }

      _refreshCompleter?.complete();
    } catch (e) {
      _refreshCompleter?.completeError(e);
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ── Health ──
  Future<ApiResponse<Map<String, dynamic>>> health() async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.get(Uri.parse(_url('/api/health')));
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, (d) => d as Map<String, dynamic>);
    });
  }

  // ── Auth ──
  Future<ApiResponse<AuthData>> register(String username, String password) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.post(
        Uri.parse(_url('/api/auth/register')),
        headers: await _headers(),
        body: jsonEncode({'username': username, 'password': password}),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '注册失败');
      }
      return ApiResponse.fromJson(json, (d) => AuthData.fromJson(d as Map<String, dynamic>));
    });
  }

  Future<ApiResponse<AuthData>> login(String username, String password) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.post(
        Uri.parse(_url('/api/auth/login')),
        headers: await _headers(),
        body: jsonEncode({'username': username, 'password': password}),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '登录失败');
      }
      return ApiResponse.fromJson(json, (d) => AuthData.fromJson(d as Map<String, dynamic>));
    });
  }

  Future<ApiResponse<UserInfo>> getMe() async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.get(
        Uri.parse(_url('/api/auth/me')),
        headers: await _headers(),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, (d) => UserInfo.fromJson(d as Map<String, dynamic>));
    });
  }

  // ── Progress ──
  Future<ApiResponse<List<AnimeProgress>>> listProgress() async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.get(
        Uri.parse(_url('/api/progress')),
        headers: await _headers(),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '获取列表失败');
      }
      return ApiResponse.fromJson(json, (d) {
        return (d as List<dynamic>)
            .map((e) => AnimeProgress.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResponse<AnimeProgress>> create(Map<String, dynamic> body) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.post(
        Uri.parse(_url('/api/progress')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '创建失败');
      }
      return ApiResponse.fromJson(json, (d) => AnimeProgress.fromJson(d as Map<String, dynamic>));
    });
  }

  Future<ApiResponse<AnimeProgress>> update(int id, Map<String, dynamic> body) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.put(
        Uri.parse(_url('/api/progress/$id')),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '更新失败');
      }
      return ApiResponse.fromJson(json, (d) => AnimeProgress.fromJson(d as Map<String, dynamic>));
    });
  }

  Future<ApiResponse<AnimeProgress>> watch(int id, int delta) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.patch(
        Uri.parse(_url('/api/progress/$id/watch')),
        headers: await _headers(),
        body: jsonEncode({'delta': delta}),
      );
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '操作失败');
      }
      return ApiResponse.fromJson(json, (d) => AnimeProgress.fromJson(d as Map<String, dynamic>));
    });
  }

  Future<void> delete(int id) async {
    return _executeWithAuthRefresh(() async {
      final r = await _client.delete(
        Uri.parse(_url('/api/progress/$id')),
        headers: await _headers(),
      );
      if (r.statusCode != 200) {
        final json = jsonDecode(r.body) as Map<String, dynamic>;
        throw ApiException(r.statusCode, json['detail']?.toString() ?? '删除失败');
      }
      return;
    });
  }

  void dispose() {
    _client.close();
  }
}
