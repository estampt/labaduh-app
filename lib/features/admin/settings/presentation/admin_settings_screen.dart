import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/admin_settings_controller.dart';

import '../../../../core/auth/logout_helper.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(adminSettingsProvider);
    final c = ref.read(adminSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('Platform service fee'),
              subtitle: Text('${s.platformFeePct}% (applied to subtotal)'),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  var v = s.platformFeePct;
                  final result = await showDialog<int>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Set service fee %'),
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: v > 0 ? () => v -= 1 : null, icon: const Icon(Icons.remove_circle_outline)),
                          Text('$v', style: const TextStyle(fontWeight: FontWeight.w900)),
                          IconButton(onPressed: () => v += 1, icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, v), child: const Text('Save')),
                      ],
                    ),
                  );
                  if (result != null) c.setFeePct(result);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              value: s.matchingEnabled,
              onChanged: c.setMatching,
              title: const Text('Matching enabled', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Turn off to pause new orders platform-wide'),
              secondary: const Icon(Icons.hub_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              value: s.vendorSubscriptionEnabled,
              onChanged: c.setSubscription,
              title: const Text('Vendor subscriptions', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Enable prioritization plans (Free/Pro/Elite)'),
              secondary: const Icon(Icons.workspace_premium_outlined),
            ),
          ),
          // ---------------- LOGOUT ----------------
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of this device'),
                onTap: () async {
                  await performLogout(
                    ref: ref,
                    router: GoRouter.of(context),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
