import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:labaduh/core/auth/session_notifier.dart';
import 'package:labaduh/core/network/dio_provider.dart';

Future<void> performLogout({
  required WidgetRef ref,
  required GoRouter router,
}) async {
  // ✅ 0) Clear Dio Authorization header (and cancel requests if you support it)
  final dio = ref.read(dioProvider); // make sure this matches your provider name
  dio.options.headers.remove('Authorization');

  // 1) Clear secure storage
  final store = ref.read(tokenStorageProvider);
  await store.clearToken();

  // 2) Reset in-memory session
  final session = ref.read(sessionNotifierProvider);
  session.token = null;
  session.userType = null;
  session.vendorApproval = null;
  session.vendorId = null;
  session.activeShopId = null;
  session.activeShopName = null;
  session.clearEphemeral();

  // ✅ 3) Navigate FIRST (prevents UI from rebuilding protected screens)
  router.go('/login');

  // ✅ 4) Then refresh session (safe after route change)
  session.refresh();
}