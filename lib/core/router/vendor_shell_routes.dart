import 'package:go_router/go_router.dart';

import '../../features/vendor/shell/presentation/vendor_shell.dart';
import '../../features/vendor/dashboard/presentation/vendor_dashboard_tab.dart';
import '../../features/vendor/orders/presentation/vendor_orders_tab.dart';
import '../../features/vendor/orders/presentation/vendor_order_detail_screen.dart';
import '../../features/vendor/earnings/presentation/vendor_earnings_tab.dart';
import '../../features/vendor/profile/presentation/vendor_profile_tab.dart';

/// Vendor UI routes (Option 1: Bottom Tabs).
final List<RouteBase> vendorShellRoutes = [
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => VendorShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/v/home', builder: (context, state) => const VendorDashboardTab()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/v/orders',
            builder: (context, state) => const VendorOrdersTab(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => VendorOrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/v/earnings', builder: (context, state) => const VendorEarningsTab()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/v/profile', builder: (context, state) => const VendorProfileTab()),
        ],
      ),
    ],
  ),
];
