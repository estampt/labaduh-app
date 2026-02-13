import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_token_api.dart';

class PushTokenService {
  PushTokenService(this._api);

  final PushTokenApi _api;

  bool _started = false;

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  /// Call this after login (token already saved), or on app start if already logged in.
  Future<void> bootstrap() async {
    if (_started) return;
    _started = true;

    await _ensurePermission();

    // initial token
    await syncNow();

    // refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await _api.registerToken(token: newToken, platform: _platform);
      } catch (_) {
        // keep silent; next bootstrap/sync will retry
      }
    });
  }

  Future<void> syncNow() async {
    await _ensurePermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    await _api.registerToken(token: token, platform: _platform);
  }

  Future<void> _ensurePermission() async {
    // iOS + Android 13+ (and web) handled here
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }
}
