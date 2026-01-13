import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';
import 'session_notifier.dart';

Future<void> performLogout({
  required WidgetRef ref,
  required GoRouter router,
}) async {
  // Optional: call backend logout + clear token
  await ref.read(authControllerProvider.notifier).logout();

  // Reset session / guards
  ref.read(sessionNotifierProvider).refresh();

  // Reset navigation stack
  router.go('/');
}
