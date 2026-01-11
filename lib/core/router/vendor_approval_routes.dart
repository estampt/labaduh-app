import 'package:go_router/go_router.dart';

import '../../features/vendor/onboarding/presentation/vendor_apply_screen.dart';
import '../../features/vendor/onboarding/presentation/vendor_pending_screen.dart';
import '../../features/vendor/onboarding/presentation/vendor_rejected_screen.dart';
import '../../features/vendor/presentation/vendor_home_screen.dart';

final List<RouteBase> vendorApprovalRoutes = [
  GoRoute(path: '/v/apply', builder: (context, state) => const VendorApplyScreen()),
  GoRoute(
    path: '/v/pending',
    builder: (context, state) => VendorPendingScreen(appId: state.uri.queryParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/v/rejected',
    builder: (context, state) => VendorRejectedScreen(appId: state.uri.queryParameters['id'] ?? ''),
  ),
  GoRoute(path: '/v/home', builder: (context, state) => const VendorHomeScreen()),
];
