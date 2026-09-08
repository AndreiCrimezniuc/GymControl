import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/subscription/pro_status.dart';
import 'package:gymboss/data/local/local_store.dart';

enum ProAccessState { unknown, loading, free, pro, unavailable }

class ProController extends ChangeNotifier {
  static const _cacheCollection = 'subscription';
  static const _cacheId = 'pro';
  static const _cacheTtl = Duration(minutes: 15);
  final AuthenticatedClient _client;
  ProStatus? _status;
  ProAccessState _state = ProAccessState.unknown;
  Future<bool>? _inFlight;

  ProController(this._client);

  bool get isPro {
    final status = _status;
    if (status == null || !status.isPro) return false;
    final expiresAt = status.expiresAt;
    return expiresAt == null || expiresAt.isAfter(DateTime.now().toUtc());
  }

  bool get loading => _state == ProAccessState.loading;
  bool get isKnown =>
      _state == ProAccessState.free || _state == ProAccessState.pro;
  ProAccessState get state => _state;
  DateTime? get expiresAt => _status?.expiresAt;

  Future<bool> load({bool force = false}) async {
    if (!force && isKnown) return true;
    if (_inFlight != null) return _inFlight!;
    _inFlight = _load();
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  Future<bool> _load() async {
    _state = ProAccessState.loading;
    notifyListeners();
    final cached = LocalStore.instance.getDoc(_cacheCollection, _cacheId);
    final hadCache = cached != null;
    if (cached != null) {
      _status = ProStatus.fromJson(cached);
      _state = isPro ? ProAccessState.pro : ProAccessState.free;
      notifyListeners();
      final cachedAt = DateTime.tryParse(cached['cached_at'] as String? ?? '');
      if (cachedAt != null &&
          DateTime.now().toUtc().difference(cachedAt) < _cacheTtl) {
        return true;
      }
    }
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/subscription/pro'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _status = ProStatus.fromJson(body);
        await LocalStore.instance.putDoc(_cacheCollection, _cacheId, {
          ...body,
          'cached_at': DateTime.now().toUtc().toIso8601String(),
        });
        _state = isPro ? ProAccessState.pro : ProAccessState.free;
        return true;
      }
      _state = ProAccessState.unavailable;
      return false;
    } catch (_) {
      if (hadCache) {
        _state = isPro ? ProAccessState.pro : ProAccessState.free;
        return true;
      }
      _state = ProAccessState.unavailable;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Temporary development control. StoreKit will replace this endpoint.
  Future<void> setPro(bool value) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/subscription/pro'),
      body: jsonEncode({'is_pro': value}),
    );
    if (response.statusCode != 200) {
      throw Exception('Could not update Pro status');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    _status = ProStatus.fromJson(body);
    await LocalStore.instance.putDoc(_cacheCollection, _cacheId, {
      ...body,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
    _state = isPro ? ProAccessState.pro : ProAccessState.free;
    notifyListeners();
  }
}
