import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';

enum ClientDiagnosticLevel { info, warning, error }

class DiagnosticSendResult {
  final String reportId;
  final int eventCount;

  const DiagnosticSendResult(this.reportId, this.eventCount);
}

/// A privacy-safe, bounded diagnostic buffer.
///
/// Callers can submit only stable event codes and a small allowlist of
/// technical attributes. Free-form messages, stack traces, request bodies,
/// account data and workout data are intentionally unsupported.
class DiagnosticService {
  DiagnosticService._();

  static final DiagnosticService instance = DiagnosticService._();
  static const _boxName = 'diagnostic_events';
  static const _maxEvents = 200;
  static const _uuid = Uuid();

  static const _allowedAttributes = {
    'screen',
    'operation',
    'status_code',
    'error_code',
    'network_state',
    'queue_size',
    'duration_ms',
  };

  Box<String>? _box;
  String _appVersion = 'unknown';
  String _buildNumber = 'unknown';

  bool get isReady => _box != null;
  int get eventCount => _box?.length ?? 0;

  Future<void> init({
    Box<String>? box,
    String? appVersion,
    String? buildNumber,
  }) async {
    _box ??= box ?? await Hive.openBox<String>(_boxName);
    if (appVersion != null && buildNumber != null) {
      _appVersion = appVersion;
      _buildNumber = buildNumber;
    } else {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    }
  }

  Future<void> record(
    String code, {
    ClientDiagnosticLevel level = ClientDiagnosticLevel.info,
    Map<String, Object?> attributes = const {},
  }) async {
    final box = _box;
    if (box == null || !_validCode(code)) return;

    final safeAttributes = <String, Object>{};
    for (final entry in attributes.entries) {
      if (!_allowedAttributes.contains(entry.key)) continue;
      final value = _sanitizeValue(entry.value);
      if (value != null) safeAttributes[entry.key] = value;
      if (safeAttributes.length == 12) break;
    }

    final id = _uuid.v4();
    await box.put(
      id,
      jsonEncode({
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'level': level.name,
        'code': code,
        if (safeAttributes.isNotEmpty) 'attributes': safeAttributes,
      }),
    );
    while (box.length > _maxEvents) {
      await box.delete(box.keys.first);
    }
  }

  Future<DiagnosticSendResult> send(AuthenticatedClient client) async {
    final box = _box;
    if (box == null || box.isEmpty) {
      throw StateError('No diagnostic events to send');
    }

    // Snapshot keys so events recorded during upload remain in the buffer.
    final keys = box.keys.cast<String>().take(_maxEvents).toList();
    final events = keys
        .map((key) => box.get(key))
        .whereType<String>()
        .map((value) => jsonDecode(value) as Map<String, dynamic>)
        .toList();
    final reportId = _uuid.v4();
    final response = await client
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/diagnostics'),
          body: jsonEncode({
            'report_id': reportId,
            'app_version': _appVersion,
            'build_number': _buildNumber,
            'platform': _platform,
            'events': events,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 202) {
      throw StateError('Diagnostics upload failed (${response.statusCode})');
    }
    await box.deleteAll(keys);
    return DiagnosticSendResult(reportId, events.length);
  }

  @visibleForTesting
  static Map<String, Object> sanitizeAttributes(
    Map<String, Object?> attributes,
  ) {
    final safe = <String, Object>{};
    for (final entry in attributes.entries) {
      if (!_allowedAttributes.contains(entry.key)) continue;
      final value = _sanitizeValue(entry.value);
      if (value != null) safe[entry.key] = value;
      if (safe.length == 12) break;
    }
    return safe;
  }

  static bool _validCode(String code) =>
      RegExp(r'^[a-z0-9][a-z0-9_.-]{0,63}$').hasMatch(code);

  static Object? _sanitizeValue(Object? value) {
    if (value is bool || value is num) return value;
    if (value is! String) return null;
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > 120 ||
        normalized.contains('@') ||
        normalized.toLowerCase().contains('bearer ') ||
        (normalized.startsWith('eyJ') &&
            '.'.allMatches(normalized).length >= 2)) {
      return null;
    }
    return normalized;
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'linux',
    };
  }
}
