import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.read(dioProvider);
  return ApiClient(dio);
});

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  // TODO: Implement with your Laravel endpoints
  Future<void> login({required String email, required String password}) async {
    // Example:
    // final res = await _api.post<Map<String, dynamic>>('/auth/login', body: {
    //   'email': email,
    //   'password': password,
    // });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthRepository(api);
});
