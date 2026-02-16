import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// adjust these imports to your actual files
import 'package:labaduh/core/auth/session_notifier.dart'; // contains sessionNotifierProvider 
import 'package:labaduh/core/network/dio_provider.dart'; 
Future<void> performLogout({
  required WidgetRef ref,
  required GoRouter router,
}) async {
  // 1) Clear secure storage
  final store = ref.read(tokenStorageProvider);
  await store.clearToken();

  // 2) Reset in-memory session so guards/redirects update immediately
  final session = ref.read(sessionNotifierProvider);
  session.token = null;
  session.userType = null;
  session.vendorApproval = null;
  session.vendorId = null;
  session.activeShopId = null;
  session.activeShopName = null;
  session.clearEphemeral(); // clear active shop and other ephemeral session data
  session.refresh();
  
  // 3) Navigate to login (change if your route is different)
  router.go('/login');
}
