import 'package:go_router/go_router.dart';

import '../../features/vendor/onboarding/presentation/vendor_apply_screen.dart';
import '../../features/vendor/onboarding/presentation/vendor_pending_screen.dart';
import '../../features/vendor/onboarding/presentation/vendor_rejected_screen.dart';

/// Vendor onboarding / approval routes.
/// IMPORTANT:
/// - Do NOT register /v/home here. /v/home must come from `vendorShellRoutes`
///   so it shows the real vendor shell (Dashboard/Orders/Earnings/Profile).
final List<RouteBase> vendorApprovalRoutes = [
  GoRoute(
    path: '/v/apply',
    builder: (context, state) => const VendorApplyScreen(),
  ),
  GoRoute(
    path: '/v/pending/:id',
    builder: (context, state) => VendorPendingScreen(appId: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    path: '/v/rejected/:id',
    builder: (context, state) => VendorRejectedScreen(appId: state.pathParameters['id'] ?? ''),
  ),
];
