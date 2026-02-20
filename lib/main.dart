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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment init
  Env.init(EnvMode.dev);

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Request notification permissions (iOS + Android 13+)
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('🔔 Push permission: ${settings.authorizationStatus}');

  // ✅ iOS: allow showing notifications while app is foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ Log FCM token (useful for debugging)
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('✅ FCM token: $token');

  // ✅ If app opened from terminated state via notification tap,
  // you can at least confirm payload here (routing should be handled in app.dart)
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  debugPrint('🧨 initialMessage (terminated tap): ${initial?.data}');

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  runApp(
    const ProviderScope(
      child: LabaduhApp(),
    ),
  );
}