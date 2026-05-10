import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animesync/services/storage_service.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    // 设置 SharedPreferences 的 mock 初始值
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
  });

  group('StorageService', () {
    test('serverUrl getter/setter', () async {
      expect(storage.serverUrl, isNull);
      await storage.setServerUrl('https://example.com');
      expect(storage.serverUrl, 'https://example.com');
      // trailing slash should be removed
      await storage.setServerUrl('https://example.com/');
      expect(storage.serverUrl, 'https://example.com');
    });

    test('token getter/setter', () async {
      expect(storage.token, isNull);
      await storage.setServerUrl('https://test.com'); // need a server URL to init
      await storage.saveAuth('my-token', 'myuser');
      expect(storage.token, 'my-token');
      expect(storage.username, 'myuser');
    });

    test('clearAuth removes token and username', () async {
      await storage.setServerUrl('https://test.com');
      await storage.saveAuth('token', 'user');
      expect(storage.token, 'token');
      expect(storage.username, 'user');
      await storage.clearAuth();
      expect(storage.token, isNull);
      expect(storage.username, isNull);
    });

    test('serverUrl persists across init calls', () async {
      // First instance
      final storage1 = StorageService();
      await storage1.init();
      await storage1.setServerUrl('https://server1.com');

      // Load from same mock preferences in a new instance
      final storage2 = StorageService();
      await storage2.init();
      expect(storage2.serverUrl, 'https://server1.com');
    });
  });
}
