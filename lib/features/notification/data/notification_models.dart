class AppNotification {
  final String id;
  final DateTime createdAt;
  final DateTime? readAt;

  /// decoded from Laravel notifications.data (JSON)
  final Map<String, dynamic> payload;

  AppNotification({
    required this.id,
    required this.createdAt,
    required this.readAt,
    required this.payload,
  });

  String get type => (payload['type'] ?? '').toString(); // ops | chat
  String get title => (payload['title'] ?? '').toString();
  String get body => (payload['body'] ?? '').toString();

  Map<String, dynamic> get ref =>
      (payload['ref'] is Map<String, dynamic>) ? payload['ref'] as Map<String, dynamic> : const {};

  String get screen => (payload['screen'] ?? '').toString();

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final data = j['data'];
    final payload = (data is Map<String, dynamic>)
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

    return AppNotification(
      id: (j['id'] ?? '').toString(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      readAt: (j['read_at'] == null) ? null : DateTime.tryParse(j['read_at'].toString()),
      payload: payload,
    );
  }
}

class NotificationsPage {
  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int perPage;

  NotificationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
  });

  factory NotificationsPage.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is List) ? (j['data'] as List) : const [];
    return NotificationsPage(
      items: data
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      currentPage: (j['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (j['last_page'] as num?)?.toInt() ?? 1,
      perPage: (j['per_page'] as num?)?.toInt() ?? 20,
    );
  }
}
