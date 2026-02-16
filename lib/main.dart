import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/config/env.dart';

/// 🔔 Background push handler (REQUIRED)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('📩 BG message: ${message.data}');
}

/// ✅ NEW: Ask notification permission (Android 13+/iOS) + print token
Future<void> _initNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // Ask permission (Android 13+/iOS). On older Android, this won’t hurt.
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

  // Helpful debug: print the current FCM token
  final token = await messaging.getToken();
  debugPrint('✅ FCM token: $token');

  // If token changes later, log it
  FirebaseMessaging.instance.onTokenRefresh.listen((t) {
    debugPrint('🔄 FCM token refreshed: $t');
  });

  // Optional: log foreground messages (so you know pushes are arriving)
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('📩 FG message received: ${message.notification?.title} | ${message.data}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment init
  Env.init(EnvMode.dev);

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ NEW: ask permission + print token
  await _initNotifications();

  runApp(
    const ProviderScope(
      child: LabaduhApp(),
    ),
  );
}
