import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // <-- add this

import '../../features/auth/data/token_store.dart';
import '../../features/auth/state/auth_providers.dart';

class ApiClient {
  ApiClient({required String baseUrl, required TokenStore tokenStore})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            // ✅ Force Dio to treat responses as JSON (avoid "String raw data")
            responseType: ResponseType.json,
            // ✅ If Laravel still returns a string sometimes, we’ll decode it below
            // receiveDataWhenStatusError keeps body for 4xx/5xx too
            receiveDataWhenStatusError: true,

            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        // ✅ Ensure res.data is a Map/List when server sends JSON (even if Dio got a String)
        onResponse: (response, handler) {
          final data = response.data;

          if (data is String) {
            final trimmed = data.trim();

            // If your server sometimes prefixes like "$data{...}", strip before decoding
            final idx = trimmed.indexOf('{');
            final jsonCandidate = idx >= 0 ? trimmed.substring(idx) : trimmed;

            try {
              response.data = jsonDecode(jsonCandidate);
            } catch (_) {
              // keep original string if decoding fails
              response.data = data;
            }
          }

          handler.next(response);
        },

        onError: (DioException e, handler) {
          // Also try to decode error response bodies that come as String
          final data = e.response?.data;
          if (data is String) {
            final trimmed = data.trim();
            final idx = trimmed.indexOf('{');
            final jsonCandidate = idx >= 0 ? trimmed.substring(idx) : trimmed;

            try {
              e.response?.data = jsonDecode(jsonCandidate);
            } catch (_) {
              // ignore
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  final Dio dio;
}

/// Provider: adjust baseUrl for emulator/web if needed.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);

  // Priority:
  // 1) --dart-define=API_BASE_URL=http://...
  // 2) platform defaults (android emulator vs web/desktop)
  const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final baseUrl = envBaseUrl.isNotEmpty ? envBaseUrl : _defaultBaseUrlForPlatform();

  return ApiClient(
    baseUrl: baseUrl,
    tokenStore: tokenStore,
  );
});

String _defaultBaseUrlForPlatform() {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

