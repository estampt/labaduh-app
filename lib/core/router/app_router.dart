import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/role_select_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/customer/order/presentation/customer_home_screen.dart';
import '../../features/customer/order/presentation/order_services_screen.dart';
import '../../features/customer/order/presentation/order_schedule_screen.dart';
import '../../features/customer/order/presentation/order_review_screen.dart';
import '../../features/customer/order/presentation/order_matching_screen.dart';
import '../../features/customer/order/presentation/order_tracking_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/role', builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Customer App
      GoRoute(path: '/c/home', builder: (context, state) => const CustomerHomeScreen()),
      GoRoute(path: '/c/order/services', builder: (context, state) => const OrderServicesScreen()),
      GoRoute(path: '/c/order/schedule', builder: (context, state) => const OrderScheduleScreen()),
      GoRoute(path: '/c/order/review', builder: (context, state) => const OrderReviewScreen()),
      GoRoute(path: '/c/order/matching', builder: (context, state) => const OrderMatchingScreen()),
      GoRoute(path: '/c/order/tracking', builder: (context, state) => const OrderTrackingScreen()),
    ],
  );
});
