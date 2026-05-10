import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyServerUrl = 'server_url';
  static const _keyToken = 'token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUsername = 'username';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url);
  }

  String? get serverUrl => _prefs.getString(_keyServerUrl);

  Future<void> saveAuth(String token, String username) async {
    await _prefs.setString(_keyToken, token);
    await _prefs.setString(_keyUsername, username);
  }

  // 单独设置 access token
  Future<void> setAccessToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? get token => _prefs.getString(_keyToken);

  Future<void> setRefreshToken(String token) async {
    await _prefs.setString(_keyRefreshToken, token);
  }

  String? get refreshToken => _prefs.getString(_keyRefreshToken);

  String? get username => _prefs.getString(_keyUsername);

  Future<void> clearAuth() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUsername);
  }
}
