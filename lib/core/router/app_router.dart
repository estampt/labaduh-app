import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admin_routes.dart';

import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/role_select_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/customer/shell/presentation/customer_shell.dart';
import '../../features/customer/home/presentation/customer_home_tab.dart';
import '../../features/customer/orders/presentation/orders_tab.dart';
import '../../features/customer/orders/presentation/order_detail_screen.dart';
import '../../features/customer/wallet/presentation/wallet_tab.dart';
import '../../features/customer/profile/presentation/profile_tab.dart';
import '../../features/customer/profile/presentation/address_book_screen.dart';
import '../../features/customer/profile/presentation/address_edit_screen.dart';
import '../../features/customer/profile/presentation/settings_screen.dart';
import '../../features/customer/profile/presentation/payment_methods_screen.dart';
import '../../features/customer/support/presentation/support_screen.dart';

import '../../features/customer/order/presentation/order_services_screen.dart';
import '../../features/customer/order/presentation/order_schedule_screen.dart';
import '../../features/customer/order/presentation/order_review_screen.dart';
import '../../features/customer/order/presentation/order_matching_screen.dart';
import '../../features/customer/order/presentation/order_tracking_screen.dart';
import '../../features/customer/order/presentation/order_success_screen.dart';
import '../../features/customer/order/presentation/order_rate_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/role', builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/c/home', builder: (context, state) => const CustomerHomeTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/orders',
                builder: (context, state) => const OrdersTab(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/c/wallet', builder: (context, state) => const WalletTab()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/profile',
                builder: (context, state) => const ProfileTab(),
                routes: [
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressBookScreen(),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => AddressEditScreen(address: state.extra),
                      ),
                    ],
                  ),
                  GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
                  GoRoute(path: 'payments', builder: (context, state) => const PaymentMethodsScreen()),
                  GoRoute(path: 'support', builder: (context, state) => const SupportScreen()),
                ],
              ),
            ],
          ),
        ],
      ),

      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/services', builder: (context, state) => const OrderServicesScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/schedule', builder: (context, state) => const OrderScheduleScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/review', builder: (context, state) => const OrderReviewScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/matching', builder: (context, state) => const OrderMatchingScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/tracking', builder: (context, state) => const OrderTrackingScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/success', builder: (context, state) => const OrderSuccessScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/c/order/rate', builder: (context, state) => const OrderRateScreen()),
       // ✅ ADD THIS (this registers /a/overview and all admin routes)
      ...adminRoutes,
    ],
  );
});
