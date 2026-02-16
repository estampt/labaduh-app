import '../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> updateActiveShop({
    required String token,
    required int activeShopId,
  }) async {
    debugPrint('🟡 [PushTokenAPI] Sending update → token: $token | shop: $activeShopId');

    final res = await _client.dio.post(
      '/api/v1/push/token',
      data: {
        'token': token,
        'active_shop_id': activeShopId,
      },
    );

    debugPrint('🟢 [PushTokenAPI] Response → ${res.statusCode} ${res.data}');
  }


}
