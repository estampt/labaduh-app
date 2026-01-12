import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'token_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokenStore);
  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.dio.post(
      '/api/v1/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'user_type': 'customer',
      },
    );

    final data = res.data as Map<String, dynamic>;
    final token = (data['token'] ?? '') as String;
    if (token.isNotEmpty) {
      await _tokenStore.saveSession(token: token, userType: 'customer');
    }
  }

  /// Returns vendor id if present (used for /v/pending/:id routing).
  Future<String?> registerVendorMultipart({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required double latitude,
    required double longitude,
    required String businessRegistrationPath,
    required String governmentIdPath,
    List<String> supportingDocPaths = const [],
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'email': email,
      'password': password,
      'user_type': 'vendor',
      'business_name': businessName,
      'latitude': latitude,
      'longitude': longitude,
      'business_registration': await MultipartFile.fromFile(businessRegistrationPath),
      'government_id': await MultipartFile.fromFile(governmentIdPath),
      if (supportingDocPaths.isNotEmpty)
        'supporting_documents[]': [
          for (final p in supportingDocPaths) await MultipartFile.fromFile(p),
        ],
    });

    final res = await _api.dio.post(
      '/api/v1/auth/register',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data as Map<String, dynamic>;
    final token = (data['token'] ?? '') as String;

    final vendor = data['vendor'];
    final vendorId = vendor is Map<String, dynamic> ? (vendor['id']?.toString()) : null;
    final approval = vendor is Map<String, dynamic> ? (vendor['approval_status']?.toString()) : null;

    if (token.isNotEmpty) {
      await _tokenStore.saveSession(
        token: token,
        userType: 'vendor',
        vendorApprovalStatus: approval,
        vendorId: vendorId,
      );
    }

    return vendorId;
  }

  /// Poll current user's vendor approval status using /auth/me.
  /// Update keys in secure storage for routing/guards.
  Future<String?> refreshMe() async {
    final res = await _api.dio.get('/api/v1/auth/me');
    final data = res.data as Map<String, dynamic>;

    final user = data['user'] as Map<String, dynamic>?;
    final userType = (user?['user_type'] ?? user?['type'] ?? '').toString();

    final vendor = data['vendor'];
    final approval = vendor is Map<String, dynamic> ? (vendor['approval_status']?.toString()) : null;
    final vendorId = vendor is Map<String, dynamic> ? (vendor['id']?.toString()) : null;

    // Keep existing token, only refresh metadata.
    final token = await _tokenStore.readToken() ?? '';
    if (token.isNotEmpty && userType.isNotEmpty) {
      await _tokenStore.saveSession(
        token: token,
        userType: userType,
        vendorApprovalStatus: approval,
        vendorId: vendorId,
      );
    }
    return approval;
  }
}
