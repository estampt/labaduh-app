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
    print('🔔 Notification tapped');

    // --------------------------------------------
    // RAW PAYLOAD
    // --------------------------------------------
    print('📦 Full payload: $data');

    final route = data['route']?.toString();
    print('➡️ Route from payload: $route');

    // --------------------------------------------
    // DIRECT ROUTE HANDLING
    // --------------------------------------------
    if (route != null && route.startsWith('/')) {
      print('🚀 Navigating via route: $route');

      try {
        _router.go(route);
        print('✅ Navigation success via route');
      } catch (e) {
        print('❌ Navigation error: $e');
      }

      return;
    }

    // --------------------------------------------
    // TYPE CHECK
    // --------------------------------------------
    final type = data['type']?.toString();
    print('🧩 Notification type: $type');

    // --------------------------------------------
    // ORDER BROADCAST HANDLING
    // --------------------------------------------
    if (type == 'order_broadcast') {
      final raw = data['broadcast_id'] ?? data['order_broadcast_id'];

      print('🆔 Raw broadcast id: $raw');

      final broadcastId =
          int.tryParse(raw?.toString() ?? '') ?? 0;

      print('🔢 Parsed broadcast id: $broadcastId');

      if (broadcastId > 0) {
        final targetRoute = '/v/home/$broadcastId';

        print('🚀 Navigating to: $targetRoute');

        try {
          _router.go(targetRoute);
          print('✅ Navigation success');
        } catch (e) {
          print('❌ Navigation error: $e');
        }

        return;
      } else {
        print('⚠️ Invalid broadcast id');
      }
    }

    // --------------------------------------------
    // JOB OFFER
    // --------------------------------------------
    if (type == 'job_offer') {
      print('🚀 Navigating to job offers');
      _router.go('/v/job-offers');
      return;
    }

    // --------------------------------------------
    // ORDER UPDATE
    // --------------------------------------------
    if (type == 'order_update') {
      final id = data['order_id'];

      print('🆔 Order update id: $id');

      if (id != null) {
        final targetRoute = '/c/orders/$id';

        print('🚀 Navigating to: $targetRoute');
        _router.go(targetRoute);
        return;
      }

      print('🚀 Navigating to tracking fallback');
      _router.go('/c/order/tracking');
      return;
    }

    // --------------------------------------------
    // DEFAULT FALLBACK
    // --------------------------------------------
    print('⚠️ No mapping matched → opening notifications');

    _router.go('/notifications');
  }

}
