
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStage { setup, auth, home }

class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  ApiService? _api;
  String? _error;
  bool _loading = false;

  AuthProvider(this._storage);

  // State
  AuthStage get currentScreen {
    if (_storage.serverUrl == null || _storage.serverUrl!.isEmpty) {
      return AuthStage.setup;
    }
    if (_storage.token == null) {
      return AuthStage.auth;
    }
    return AuthStage.home;
  }

  String? get serverUrl => _storage.serverUrl;
  String? get username => _storage.username;
  String? get token => _storage.token;
  String? get error => _error;
  bool get isLoading => _loading;

  void _ensureApi() {
    if (_api == null && _storage.serverUrl != null) {
      _api = ApiService(
        baseUrl: _storage.serverUrl!,
        getToken: () async => _storage.token,
      );
    }
  }

  // ── Setup ──
  Future<bool> connect(String url) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _api = ApiService(baseUrl: url, getToken: () async => null);
      final r = await _api!.health();
      if (r.code == 200) {
        await _storage.setServerUrl(url);
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = '服务器不可用';
    } catch (e) {
      _error = '无法连接: $e';
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  // ── Auth ──
  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _ensureApi();
      final r = await _api!.login(username, password);
      if (r.data != null) {
        await _storage.saveAuth(r.data!.accessToken, r.data!.user.username);
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = r.message;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _ensureApi();
      final r = await _api!.register(username, password);
      if (r.data != null) {
        await _storage.saveAuth(r.data!.accessToken, r.data!.user.username);
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = r.message;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    notifyListeners();
  }
}
