
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/models.dart';

class ProgressProvider extends ChangeNotifier {
  final StorageService _storage;
  ApiService? _api;
  List<AnimeProgress> _items = [];
  String? _filterStatus; // null = all
  String? _error;
  bool _loading = false;

  ProgressProvider(this._storage);

  List<AnimeProgress> get items => _filterStatus == null
      ? _items
      : _items.where((a) => a.status == _filterStatus).toList();

  String? get filterStatus => _filterStatus;
  String? get error => _error;
  bool get isLoading => _loading;

  void _ensureApi() {
    if (_api == null && _storage.serverUrl != null && _storage.token != null) {
      _api = ApiService(
        baseUrl: _storage.serverUrl!,
        getToken: () async => _storage.token,
      );
      load();
    }
  }

  void setFilter(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> load() async {
    _ensureApi();
    if (_api == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final r = await _api!.listProgress();
      if (r.data != null) {
        _items = r.data!;
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> body) async {
    _ensureApi();
    try {
      await _api!.create(body);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> body) async {
    _ensureApi();
    try {
      await _api!.update(id, body);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> watch(int id, {int delta = 1}) async {
    _ensureApi();
    try {
      await _api!.watch(id, delta);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    _ensureApi();
    try {
      await _api!.delete(id);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _api?.dispose();
    super.dispose();
  }
}
