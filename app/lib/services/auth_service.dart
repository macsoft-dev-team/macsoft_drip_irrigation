import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_user.dart';

/// Decodes a JSON Web Token's payload WITHOUT verifying the signature.
/// Safe for reading role / id from a trusted server-issued token.
Map<String, dynamic>? _decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    // Base64url → base64
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    // Pad to multiple of 4
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // ── Token persistence ──────────────────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ── User from stored token (restore on app launch) ─────────────────────────

  static Future<({String token, AppUser user})?> restoreSession() async {
    final token = await readToken();
    if (token == null) return null;
    final payload = _decodeJwt(token);
    if (payload == null) return null;

    // Check expiry
    final exp = payload['exp'];
    if (exp != null) {
      final expMs = (exp as int) * 1000;
      if (DateTime.now().millisecondsSinceEpoch > expMs) {
        await clearToken();
        return null;
      }
    }

    final user = AppUser.fromTokenPayload(payload);
    return (token: token, user: user);
  }

  // ── Parse a freshly received token ────────────────────────────────────────

  static AppUser? userFromToken(String token) {
    final payload = _decodeJwt(token);
    if (payload == null) return null;
    return AppUser.fromTokenPayload(payload);
  }
}
