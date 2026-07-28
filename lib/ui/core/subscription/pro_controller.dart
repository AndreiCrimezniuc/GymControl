import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/domain/models/subscription/pro_status.dart';

class ProController extends ChangeNotifier {
  final AuthenticatedClient _client;
  ProStatus? _status;
  bool _loading = false;

  ProController(this._client);

  bool get isPro => _status?.isPro ?? false;
  bool get loading => _loading;

  Future<void> load() async {
    if (_status != null || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/subscription/pro'),
      );
      if (response.statusCode == 200) {
        _status = ProStatus.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } finally {
      _loading = false;
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
    _status = ProStatus(isPro: value);
    notifyListeners();
  }
}
