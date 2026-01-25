import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

import 'app.dart';
import 'core/config/env.dart';

/// REQUIRED: top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler is not used on web
  if (kIsWeb) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // TODO: you can log/store message.data if needed
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment here (dev/prod). You can later wire this to flavors.
  Env.init(EnvMode.dev);

  // Init Firebase (works on all platforms as long as options exist)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Skip FCM messaging setup on Web (avoids app "stuck" on web)
  if (!kIsWeb) {
    // Background notifications handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ask permission (iOS + Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Push permission: ${settings.authorizationStatus}');

    // Get FCM token (you will send this to Laravel later)
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $token');

    // Token refresh (important!)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('FCM TOKEN REFRESHED: $newToken');
      // TODO: call your API to update token in DB
    });

    // Foreground message listener (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM onMessage: ${message.data}');
      // TODO: show in-app banner OR local notification later
    });

    // When user taps notification (app opened from tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM clicked: ${message.data}');
      // TODO: navigate to chat/notification screen using message.data
    });
  } else {
    debugPrint('Running on Web: skipping FirebaseMessaging init.');
  }

  runApp(const ProviderScope(child: LabaduhApp()));
}
