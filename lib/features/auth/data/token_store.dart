import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _tokenKey = 'auth_token';
  static const _userTypeKey = 'auth_user_type';
  static const _vendorStatusKey = 'vendor_approval_status';
  static const _vendorIdKey = 'vendor_id';

  final FlutterSecureStorage _storage;
  const TokenStore(this._storage);

 Future<void> saveSession({
  required String token,
  required String userType,
  String? vendorApprovalStatus,
  String? vendorId,
}) async {
  await _storage.write(key: _tokenKey, value: token);
  await _storage.write(key: _userTypeKey, value: userType);

  // ✅ vendor approval: write if value exists, otherwise clear it
  if (vendorApprovalStatus == null || vendorApprovalStatus.isEmpty) {
    await _storage.delete(key: _vendorStatusKey);
  } else {
    await _storage.write(key: _vendorStatusKey, value: vendorApprovalStatus);
  }

  // ✅ vendor id: write if exists, otherwise clear it
  if (vendorId == null || vendorId.isEmpty) {
    await _storage.delete(key: _vendorIdKey);
  } else {
    await _storage.write(key: _vendorIdKey, value: vendorId);
  }
}


  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<String?> readUserType() => _storage.read(key: _userTypeKey);
  Future<String?> readVendorApprovalStatus() => _storage.read(key: _vendorStatusKey);
  Future<String?> readVendorId() => _storage.read(key: _vendorIdKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _vendorStatusKey);
    await _storage.delete(key: _vendorIdKey);
  }
}
