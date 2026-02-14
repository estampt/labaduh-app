import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_token_api.dart';

class PushTokenService {
  PushTokenService(this._api);

  final PushTokenApi _api;

  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      final fcm = FirebaseMessaging.instance;

      // 1) Ask permission (iOS + Android 13+)
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push permission: ${settings.authorizationStatus}');

      // 2) Get token and register
      final token = await fcm.getToken();
      debugPrint('FCM TOKEN: $token');

      if (token != null && token.isNotEmpty) {
        await _register(token);
      }

      // 3) Token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM TOKEN REFRESH: $newToken');
        if (newToken.isNotEmpty) {
          await _register(newToken);
        }
      });
    } catch (e, st) {
      debugPrint('Push bootstrap error: $e\n$st');
      // allow retry if something failed before any registration
      _bootstrapped = false;
    }
  }

  Future<void> _register(String token) async {
    try {
      await _api.registerToken(
        token: token,
        platform: defaultTargetPlatform.name, // "android" / "ios"
        // deviceId: optional if your api supports it
      );
      debugPrint('✅ FCM token registered to backend.');
    } catch (e, st) {
      debugPrint('❌ Register token failed: $e\n$st');
      // allow retry on next app open/login
      _bootstrapped = false;
      rethrow;
    }
  }
}
