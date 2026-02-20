import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:labaduh/core/auth/session_notifier.dart';
import 'package:labaduh/features/vendor/orders/presentation/order_acceptance_screen.dart';

import '../../features/vendor/shell/presentation/vendor_shell.dart';
import '../../features/vendor/dashboard/presentation/vendor_dashboard_tab.dart';
import '../../features/vendor/orders/presentation/vendor_orders_tab.dart';
import '../../features/vendor/orders/presentation/order_details.dart';
import '../../features/vendor/earnings/presentation/vendor_earnings_tab.dart';
import '../../features/vendor/profile/presentation/vendor_profile_tab.dart';

import '../../features/vendor/shops/presentation/vendor_shops_screen.dart';
import '../../features/vendor/shops/presentation/shop_selection_page.dart';

final List<RouteBase> vendorShellRoutes = [
  // =========================================================
  // SELECT SHOP (OUTSIDE SHELL)
  // =========================================================
  GoRoute(
    path: '/v/select-shop',
    builder: (context, state) => const ShopSelectionPage(),
  ),

  // =========================================================
  // VENDOR SHELL
  // =========================================================
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        VendorShell(navigationShell: navigationShell),

    branches: [
      // =====================================================
      // 0️⃣ HOME / DASHBOARD
      // =====================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/v/home',
            builder: (context, state) => const VendorDashboardTab(),
          ),

          // -------------------------------
          // /v/home/:orderId
          // -------------------------------
          GoRoute(
            path: '/v/home',
            builder: (context, state) => const VendorDashboardTab(),

            routes: [
              // =====================================================
              // OPTIONAL PARAM CHILD
              // /v/home/:id
              // =====================================================
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final orderId =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

                  return Consumer(
                    builder: (context, ref, _) {
                      final session = ref.read(sessionNotifierProvider);

                      final vendorId =
                          int.tryParse(session.vendorId ?? '0') ?? 0;
                      final shopId = session.activeShopId ?? 0;

                      return OrderAcceptanceScreen(
                        orderId: orderId,
                        vendorId: vendorId,
                        shopId: shopId,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // =====================================================
      // 1️⃣ ORDERS
      // =====================================================
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

                  return Consumer(
                    builder: (context, ref, _) {
                      final session = ref.read(sessionNotifierProvider);

                      final vendorId =
                          int.tryParse(session.vendorId ?? '0') ?? 0;
                      final shopId = session.activeShopId ?? 0;

                      return OrderDetailsScreen(
                        orderId: orderId,
                        vendorId: vendorId,
                        shopId: shopId,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // =====================================================
      // 2️⃣ EARNINGS
      // =====================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/v/earnings',
            builder: (context, state) =>
                const VendorEarningsTab(),
          ),
        ],
      ),

      // =====================================================
      // 3️⃣ SHOPS
      // =====================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/v/shops',
            builder: (context, state) =>
                const VendorShopsScreen(),
          ),
        ],
      ),

      // =====================================================
      // 4️⃣ PROFILE
      // =====================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/v/profile',
            builder: (context, state) =>
                const VendorProfileTab(),
          ),
        ],
      ),
    ],
  ),
];