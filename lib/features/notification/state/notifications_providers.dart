import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/notification_models.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return NotificationsRepository(dio);
});

/// Unread badge count per type: 'ops' or 'chat'
final notificationsUnreadCountProvider = FutureProvider.family<int, String>((ref, type) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.unreadCount(type: type);
});

class NotificationsListState {
  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationsListState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
  });

  factory NotificationsListState.initial() => const NotificationsListState(
        items: [],
        page: 1,
        hasMore: true,
        isLoadingMore: false,
      );

  NotificationsListState copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// ✅ Correct Riverpod family notifier
class NotificationsListController extends FamilyAsyncNotifier<NotificationsListState, String> {
  late String _type;

  @override
  Future<NotificationsListState> build(String type) async {
    _type = type;
    return _loadFirstPage();
  }

  Future<NotificationsListState> _loadFirstPage() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final page = await repo.list(type: _type, page: 1, perPage: 20);

    return NotificationsListState(
      items: page.items,
      page: page.currentPage,
      hasMore: page.currentPage < page.lastPage,
      isLoadingMore: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await _loadFirstPage());

    // refresh badge too
    ref.invalidate(notificationsUnreadCountProvider(_type));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final repo = ref.read(notificationsRepositoryProvider);
    final nextPage = current.page + 1;

    final page = await repo.list(type: _type, page: nextPage, perPage: 20);
    final merged = [...current.items, ...page.items];

    state = AsyncData(
      current.copyWith(
        items: merged,
        page: page.currentPage,
        hasMore: page.currentPage < page.lastPage,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> markRead(String id) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markRead(id);

    // Optimistic local update
    final current = state.valueOrNull;
    if (current != null) {
      final updated = current.items.map((n) {
        if (n.id == id && n.readAt == null) {
          return AppNotification(
            id: n.id,
            createdAt: n.createdAt,
            readAt: DateTime.now(),
            payload: n.payload,
          );
        }
        return n;
      }).toList();
      state = AsyncData(current.copyWith(items: updated));
    }

    ref.invalidate(notificationsUnreadCountProvider(_type));
  }

  Future<void> markAllRead() async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markAllRead(type: _type);

    // Optimistic local update
    final current = state.valueOrNull;
    if (current != null) {
      final now = DateTime.now();
      final updated = current.items.map((n) {
        if (n.readAt == null) {
          return AppNotification(
            id: n.id,
            createdAt: n.createdAt,
            readAt: now,
            payload: n.payload,
          );
        }
        return n;
      }).toList();
      state = AsyncData(current.copyWith(items: updated));
    }

    ref.invalidate(notificationsUnreadCountProvider(_type));
  }
}

/// ✅ Provider family (no extra typed wrapper needed)
final notificationsListProvider =
    AsyncNotifierProviderFamily<NotificationsListController, NotificationsListState, String>(
  NotificationsListController.new,
);
