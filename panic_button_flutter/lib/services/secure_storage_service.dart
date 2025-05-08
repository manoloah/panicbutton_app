import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data using the platform's secure storage
/// (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Key constants
  static const String _refreshTokenKey = 'supabase_refresh_token';
  static const String _accessTokenKey = 'supabase_access_token';

  // Storage options - iOS options for keychain
  static const _options = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    // This specifies a security level that's safe but not overly restrictive
    // The keychain is unavailable until after the user first unlocks the device
  );

  /// Stores Supabase refresh token securely
  static Future<void> storeRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
      iOptions: _options,
    );
  }

  /// Retrieves Supabase refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: _refreshTokenKey,
      iOptions: _options,
    );
  }

  /// Stores Supabase access token securely
  static Future<void> storeAccessToken(String token) async {
    await _storage.write(
      key: _accessTokenKey,
      value: token,
      iOptions: _options,
    );
  }

  /// Retrieves Supabase access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(
      key: _accessTokenKey,
      iOptions: _options,
    );
  }

  /// Deletes all stored tokens (for logout)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _refreshTokenKey, iOptions: _options);
    await _storage.delete(key: _accessTokenKey, iOptions: _options);
  }

  /// Checks if refresh token exists
  static Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
}
