import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // DEBUG: print the final resolved URL + method
        // ignore: avoid_print
        print('[DIO] ${options.method} ${options.uri}');

        final token = await tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (e, handler) {
        // DEBUG: print useful error details
        // ignore: avoid_print
        print('[DIO] ERROR uri=${e.requestOptions.uri}');
        // ignore: avoid_print
        print('[DIO] ERROR type=${e.type} message=${e.message}');
        // ignore: avoid_print
        print('[DIO] ERROR status=${e.response?.statusCode}');
        // ignore: avoid_print
        print('[DIO] ERROR data=${e.response?.data}');

        handler.next(e);
      },
    ),
  );

  return dio;
});
