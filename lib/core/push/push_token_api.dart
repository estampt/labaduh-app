import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class PushTokenApi {
  PushTokenApi(this._client);

  final ApiClient _client;

  /// Backend: POST /api/v1/push/token
  Future<void> registerToken({
    required String token,
    required String platform, // "android" | "ios" | "web"
  }) async {
    await _client.dio.post(
      '/api/v1/push/token',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
