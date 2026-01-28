import 'package:dio/dio.dart';

import 'notification_models.dart';

class NotificationsRepository {
  NotificationsRepository(this.dio);

  final Dio dio;

  Future<NotificationsPage> list({
    required String type, // ops | chat
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await dio.get(
      '/api/v1/notifications',
      queryParameters: {
        'type': type,
        'page': page,
        'per_page': perPage,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return NotificationsPage.fromJson(data);
    }
    if (data is Map) {
      return NotificationsPage.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Unexpected notifications response: ${data.runtimeType}');
  }

  Future<int> unreadCount({required String type}) async {
    final res = await dio.get(
      '/api/v1/notifications/unread-count',
      queryParameters: {'type': type},
    );

    final data = res.data;
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      return (m['unread'] as num?)?.toInt() ?? 0;
    }
    throw Exception('Unexpected unread-count response: ${data.runtimeType}');
  }

  Future<void> markRead(String id) async {
    await dio.post('/api/v1/notifications/$id/read');
  }

  Future<void> markAllRead({String? type}) async {
    await dio.post(
      '/api/v1/notifications/read-all',
      queryParameters: type == null ? null : {'type': type},
    );
  }
}
