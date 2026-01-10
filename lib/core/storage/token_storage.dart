import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kTokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _kTokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _kTokenKey);

  Future<void> clearToken() => _storage.delete(key: _kTokenKey);
}
