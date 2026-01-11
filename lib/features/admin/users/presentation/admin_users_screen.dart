import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/admin_users_controller.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final filtered = users.where((u) => q.isEmpty || u.name.toLowerCase().contains(q.toLowerCase()) || u.city.toLowerCase().contains(q.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search users'),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No users found', style: TextStyle(color: Colors.black54)))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final u = filtered[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text('${u.city} • Joined ${u.createdAt}'),
                          trailing: const Icon(Icons.more_horiz),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
