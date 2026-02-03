import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ✅ import your providers
import '../../../../features/notification/state/notifications_providers.dart'; 

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Orders';
      case 2:
        return 'Wallet';
      case 3:
        return 'Profile';
      default:
        return 'Labaduh';
    }
  }

  Widget _badgeIcon(IconData icon, {required int count, String? semanticLabel}) {
    final show = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, semanticLabel: semanticLabel),
        if (show)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _logo() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: SizedBox(
      height: 28, // sweet spot for AppBar
      child: Image.asset(
        'assets/branding/labaduh_logo.png',
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ real badge counts from API (ops + chat)
    final notifCountAsync = ref.watch(notificationsUnreadCountProvider('ops'));
    final msgCountAsync = ref.watch(notificationsUnreadCountProvider('chat'));

    final notifCount = notifCountAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final msgCount = msgCountAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            _logo(),
            const SizedBox(width: 10),
            //Expanded(child: Text(_titleForIndex(navigationShell.currentIndex))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'), // ✅ ops list screen route
            icon: _badgeIcon(
              Icons.notifications_none,
              count: notifCount,
              semanticLabel: 'Notifications',
            ),
          ),
          IconButton(
            tooltip: 'Inbox',
            onPressed: () => context.push('/messages'), // ✅ chat list screen route (rename later if you want)
            icon: _badgeIcon(
              Icons.chat_bubble_outline,
              count: msgCount,
              semanticLabel: 'Inbox',
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
