import 'package:go_router/go_router.dart';

import '../../features/vendor/shell/presentation/vendor_shell.dart';
import '../../features/vendor/dashboard/presentation/vendor_dashboard_tab.dart';
import '../../features/vendor/orders/presentation/vendor_orders_tab.dart';
import '../../features/vendor/orders/presentation/order_details.dart';
import '../../features/vendor/earnings/presentation/vendor_earnings_tab.dart';
import '../../features/vendor/profile/presentation/vendor_profile_tab.dart';

import '../../features/vendor/shops/presentation/vendor_shops_screen.dart';
import '../../features/vendor/shops/presentation/shop_selection_page.dart';

final List<RouteBase> vendorShellRoutes = [
  // ✅ IMPORTANT: this must exist, OUTSIDE the shell
  GoRoute(
    path: '/v/select-shop',
    builder: (context, state) => const ShopSelectionPage(),
  ),

  // ✅ Vendor shell tabs
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        VendorShell(navigationShell: navigationShell),
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
          builder: (context, state) {
            final orderId =
                int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

            // TODO: Replace these with your real providers/session values
            const vendorId = 2;
            const shopId = 2;

            return OrderDetailsScreen(
              orderId: orderId,
              vendorId: vendorId,
              shopId: shopId,
            );
          },
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
          GoRoute(path: '/v/shops', builder: (context, state) => const VendorShopsScreen()),
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
