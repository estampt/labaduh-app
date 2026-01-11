import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/shell/presentation/admin_shell.dart';
import '../../features/admin/overview/presentation/admin_overview_screen.dart';
import '../../features/admin/orders/presentation/admin_orders_screen.dart';
import '../../features/admin/vendors/presentation/admin_vendors_screen.dart';
import '../../features/admin/users/presentation/admin_users_screen.dart';
import '../../features/admin/pricing/presentation/admin_pricing_screen.dart';
import '../../features/admin/settings/presentation/admin_settings_screen.dart';
import '../../features/admin/orders/presentation/admin_order_detail_screen.dart';
import '../../features/admin/vendors/presentation/admin_vendor_detail_screen.dart';

final List<RouteBase> adminRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AdminShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/a/overview', builder: (context, state) => const AdminOverviewScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/a/orders',
            builder: (context, state) => const AdminOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AdminOrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/a/vendors',
            builder: (context, state) => const AdminVendorsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AdminVendorDetailScreen(vendorId: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/a/users', builder: (context, state) => const AdminUsersScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/a/pricing', builder: (context, state) => const AdminPricingScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/a/settings', builder: (context, state) => const AdminSettingsScreen()),
        ],
      ),
    ],
  ),
];

class AdminGuard {
  static String? gate(BuildContext context) => null;
}
