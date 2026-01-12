import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/token_store.dart';
import '../../features/auth/state/auth_providers.dart';

class ApiClient {
  ApiClient({required String baseUrl, required TokenStore tokenStore})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: const {'Accept': 'application/json'},
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final Dio dio;
}

/// Provider: adjust baseUrl for emulator/web if needed.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  return ApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000'),
    tokenStore: tokenStore,
  );
});
