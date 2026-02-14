import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class PushNotificationService {
  PushNotificationService(this._router);

  final GoRouter _router;

  final _local = FlutterLocalNotificationsPlugin();
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    // Init local notifications (foreground banners)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null) return;

        final data = jsonDecode(payload) as Map<String, dynamic>;
        _handleTap(data);
      },
    );

    // Foreground push
    FirebaseMessaging.onMessage.listen((msg) async {
      await _showForegroundBanner(msg);
    });

    // Background → tapped
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleTap(msg.data);
    });

    // Terminated → tapped
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleTap(initial.data);
    }
  }

  Future<void> _showForegroundBanner(RemoteMessage msg) async {
    final n = msg.notification;

    final payload = jsonEncode(msg.data);

    await _local.show(
      0,
      n?.title ?? 'Notification',
      n?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default',
          'Default',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  void _handleTap(Map<String, dynamic> data) {
    final route = data['route']?.toString();

    if (route != null && route.startsWith('/')) {
      _router.go(route);
      return;
    }

    // Fallback mappings
    final type = data['type'];

    if (type == 'job_offer') {
      _router.go('/v/job-offers');
      return;
    }

    if (type == 'order_update') {
      final id = data['order_id'];
      if (id != null) {
        _router.go('/c/orders/$id');
        return;
      }
      _router.go('/c/order/tracking');
      return;
    }

    _router.go('/notifications');
  }
}
