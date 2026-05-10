import 'package:flutter_test/flutter_test.dart';
import 'package:animesync/providers/auth_provider.dart';
import 'package:animesync/services/storage_service.dart';

class MockStorage extends StorageService {
  String? _serverUrl;
  String? _token;
  String? _username;

  @override
  String? get serverUrl => _serverUrl;

  @override
  String? get token => _token;

  @override
  String? get username => _username;

  @override
  Future<bool> setServerUrl(String url) async {
    _serverUrl = url.replaceAll(RegExp(r'/+$'), '');
    return true;
  }

  @override
  Future<void> saveAuth(String token, String username) async {
    _token = token;
    _username = username;
  }

  @override
  Future<void> clearAuth() async {
    _token = null;
    _username = null;
  }

  @override
  Future<void> init() async {}
}

void main() {
  late MockStorage mockStorage;
  late AuthProvider provider;

  setUp(() {
    mockStorage = MockStorage();
    provider = AuthProvider(mockStorage);
  });

  group('AuthProvider', () {
    test('初始状态: serverUrl 为空时返回 setup', () {
      expect(provider.currentScreen, AuthStage.setup);
      expect(provider.serverUrl, isNull);
      expect(provider.token, isNull);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('serverUrl 设置后仍为 auth (未登录)', () async {
      await mockStorage.setServerUrl('https://test.com');
      provider = AuthProvider(mockStorage);
      expect(provider.currentScreen, AuthStage.auth);
    });

    test('token 存在时返回 home', () async {
      await mockStorage.setServerUrl('https://test.com');
      await mockStorage.saveAuth('token', 'user');
      provider = AuthProvider(mockStorage);
      expect(provider.currentScreen, AuthStage.home);
      expect(provider.username, 'user');
    });

    test('logout 登出后清空 token, 返回 auth stage', () async {
      await mockStorage.setServerUrl('https://test.com');
      await mockStorage.saveAuth('token', 'user');
      provider = AuthProvider(mockStorage);
      expect(provider.currentScreen, AuthStage.home);
      provider.logout();
      expect(mockStorage.token, isNull);
      expect(mockStorage.username, isNull);
      expect(provider.currentScreen, AuthStage.auth);
    });
  });
}