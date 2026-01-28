import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/notifications_providers.dart';

class OpsNotificationsScreen extends ConsumerWidget {
  const OpsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsListProvider('ops'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsListProvider('ops').notifier).markAllRead();
            },
            child: const Text('Read all'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.read(notificationsListProvider('ops').notifier).refresh(),
          child: ListView.separated(
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= s.items.length) {
                // load more row
                ref.read(notificationsListProvider('ops').notifier).loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final n = s.items[index];
              final isUnread = n.readAt == null;

              return ListTile(
                leading: Icon(isUnread ? Icons.circle : Icons.circle_outlined, size: 12),
                title: Text(n.title.isEmpty ? '(No title)' : n.title),
                subtitle: Text(n.body),
                onTap: () async {
                  // mark read
                  if (isUnread) {
                    await ref.read(notificationsListProvider('ops').notifier).markRead(n.id);
                  }
                  // TODO: navigate using n.screen + n.ref if you want
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
