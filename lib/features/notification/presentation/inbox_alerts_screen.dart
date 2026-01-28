import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/notifications_providers.dart';

class InboxAlertsScreen extends ConsumerWidget {
  const InboxAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsListProvider('chat'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsListProvider('chat').notifier).markAllRead();
            },
            child: const Text('Read all'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.read(notificationsListProvider('chat').notifier).refresh(),
          child: ListView.separated(
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= s.items.length) {
                ref.read(notificationsListProvider('chat').notifier).loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final n = s.items[index];
              final isUnread = n.readAt == null;

              return ListTile(
                leading: Icon(isUnread ? Icons.markunread : Icons.mail_outline),
                title: Text(n.title.isEmpty ? 'New message' : n.title),
                subtitle: Text(n.body),
                onTap: () async {
                  if (isUnread) {
                    await ref.read(notificationsListProvider('chat').notifier).markRead(n.id);
                  }
                  // TODO: open conversation using n.ref['conversation_id']
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
