import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});
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
        return 'Overview';
      case 1:
        return 'Orders';
      case 2:
        return 'Vendors';
      case 3:
        return 'Users';
      case 4:
        return 'Pricing';
      case 5:
        return 'Settings';
      default:
        return 'Admin';
    }
  }

  // Placeholder badges (wire to providers later)
  static const int _notifCount = 3;
  static const int _msgCount = 1;

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
  return SizedBox(
    height: 28,          // ideal appbar logo height
    width: 170,          // cap width so it won't hit 🔔💬
    child: Image.asset(
      'assets/branding/labaduh_logo.png', // <-- change if your path is different
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            _logo(),
            const SizedBox(width: 10),
            Expanded(child: Text(_titleForIndex(navigationShell.currentIndex))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: _badgeIcon(
              Icons.notifications_none,
              count: _notifCount,
              semanticLabel: 'Notifications',
            ),
          ),
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.push('/messages'),
            icon: _badgeIcon(
              Icons.chat_bubble_outline,
              count: _msgCount,
              semanticLabel: 'Messages',
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
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: 'Vendors'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.price_change_outlined),
              selectedIcon: Icon(Icons.price_change),
              label: 'Pricing'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
