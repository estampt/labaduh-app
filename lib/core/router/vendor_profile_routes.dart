import 'package:go_router/go_router.dart';

import '../../features/vendor/profile/presentation/vendor_pricing_screen.dart';
import '../../features/vendor/profile/presentation/vendor_hours_screen.dart';
import '../../features/vendor/profile/presentation/vendor_settings_screen.dart';

final List<RouteBase> vendorProfileRoutes = [
  GoRoute(path: '/v/profile/pricing', builder: (context, state) => const VendorPricingScreen()),
  GoRoute(path: '/v/profile/hours', builder: (context, state) => const VendorHoursScreen()),
  GoRoute(path: '/v/profile/settings', builder: (context, state) => const VendorSettingsScreen()),
];
