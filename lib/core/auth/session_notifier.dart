import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';

class SessionNotifier extends ChangeNotifier {
  SessionNotifier(this.ref);
  final Ref ref;

  bool _initialized = false;

  String? token;
  String? userType; // customer/vendor/admin
  String? vendorApproval; // pending/approved/rejected
  String? vendorId;

  Future<void> load() async {
    final store = ref.read(tokenStoreProvider);
    token = await store.readToken();
    userType = await store.readUserType();
    vendorApproval = await store.readVendorApprovalStatus();
    vendorId = await store.readVendorId();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initialized = false;
    notifyListeners();
    await load();
  }

  /// Router guard (synchronous).
  String? redirect(GoRouterState state) {
    final loc = state.matchedLocation;

    // Public routes
    final isPublic = loc == '/' ||
        loc.startsWith('/login') ||
        loc.startsWith('/signup') ||
        loc.startsWith('/otp') ||
        loc.startsWith('/v/apply') ||
        loc.startsWith('/role');

    if (!_initialized) return null;

    final hasToken = token != null && token!.isNotEmpty;

    // Not logged in: send everything to landing page, except public routes.
    if (!hasToken) {
      if (isPublic) return null;
      return '/';
    }

    // Logged in: don't stay on landing/login/signup/role.
    if (isPublic) {
      if (userType == 'admin') return '/a/overview';
      if (userType == 'vendor') {
        if (vendorApproval == 'pending') return '/v/pending/${vendorId ?? '0'}';
        if (vendorApproval == 'rejected') return '/v/rejected/${vendorId ?? '0'}';
        return '/v/home';
      }
      return '/c/home';
    }

    // Area protection
    final isCustomerArea = loc.startsWith('/c');
    final isVendorArea = loc.startsWith('/v');
    final isAdminArea = loc.startsWith('/a');

    if (isCustomerArea && userType != 'customer') {
      if (userType == 'vendor') {
        if (vendorApproval == 'pending') return '/v/pending/${vendorId ?? '0'}';
        if (vendorApproval == 'rejected') return '/v/rejected/${vendorId ?? '0'}';
        return '/v/home';
      }
      if (userType == 'admin') return '/a/overview';
      return '/';
    }

    if (isVendorArea && userType != 'vendor') {
      if (userType == 'customer') return '/c/home';
      if (userType == 'admin') return '/a/overview';
      return '/';
    }

    if (isAdminArea && userType != 'admin') {
      if (userType == 'customer') return '/c/home';
      if (userType == 'vendor') {
        if (vendorApproval == 'pending') return '/v/pending/${vendorId ?? '0'}';
        if (vendorApproval == 'rejected') return '/v/rejected/${vendorId ?? '0'}';
        return '/v/home';
      }
      return '/';
    }

    // Vendor approval gating
    if (userType == 'vendor' && loc.startsWith('/v')) {
      if (vendorApproval == 'pending' && !loc.startsWith('/v/pending')) {
        return '/v/pending/${vendorId ?? '0'}';
      }
      if (vendorApproval == 'rejected' && !loc.startsWith('/v/rejected')) {
        return '/v/rejected/${vendorId ?? '0'}';
      }
    }

    return null;
  }
}

final sessionNotifierProvider = ChangeNotifierProvider<SessionNotifier>((ref) {
  return SessionNotifier(ref)..load();
});
