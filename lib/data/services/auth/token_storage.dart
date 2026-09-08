import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static const _migratedKey = 'secure_token_storage_migrated_v1';
  final FlutterSecureStorage _secure;

  TokenStorage({FlutterSecureStorage? secure})
    : _secure =
          secure ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  Future<void> save(String accessToken, String refreshToken) async {
    await _secure.write(key: _accessKey, value: accessToken);
    await _secure.write(key: _refreshKey, value: refreshToken);
    await _removeLegacyValues();
  }

  Future<String?> getAccessToken() async {
    await _migrateLegacyValues();
    return _secure.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    await _migrateLegacyValues();
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
    await _removeLegacyValues();
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _migrateLegacyValues() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    if (access != null && access.isNotEmpty) {
      await _secure.write(key: _accessKey, value: access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await _secure.write(key: _refreshKey, value: refresh);
    }
    await _removeLegacyValues();
  }

  Future<void> _removeLegacyValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.setBool(_migratedKey, true);
  }
}
