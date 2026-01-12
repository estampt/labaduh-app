import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';

/// Loads the persisted session (token + role + vendor approval status)
/// and exposes a synchronous redirect for GoRouter.
class SessionNotifier extends ChangeNotifier {
  SessionNotifier(this._ref) {
    _init();
  }

  final Ref _ref;

  bool ready = false;
  String? token;
  String? userType; // customer | vendor | admin
  String? vendorApprovalStatus; // pending | approved | rejected
  String? vendorId;

  Future<void> _init() async {
    await refresh();
    ready = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    final store = _ref.read(tokenStoreProvider);
    token = await store.readToken();
    userType = await store.readUserType();
    vendorApprovalStatus = await store.readVendorApprovalStatus();
    vendorId = await store.readVendorId();
    notifyListeners();
  }

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  /// Synchronous redirect used by GoRouter.
  /// NOTE: keep this sync; use [refresh] when session changes.
  String? redirect(GoRouterState state) {
    final loc = state.matchedLocation;

    // While session is loading, keep user on loading screen.
    if (!ready) {
      if (loc == '/') return null;
      return '/';
    }

    final isPublic = loc == '/' ||
        loc.startsWith('/role') ||
        loc.startsWith('/login') ||
        loc.startsWith('/signup');

    final isCustomerArea = loc.startsWith('/c');
    final isVendorArea = loc.startsWith('/v');
    final isAdminArea = loc.startsWith('/a');

    if (!isLoggedIn) {
      // Not logged in → allow only public routes
      if (isPublic) return null;
      return '/role';
    }

    final type = userType ?? '';

    // Logged in → landing redirects
    if (isPublic) {
      if (type == 'customer') return '/c/home';
      if (type == 'vendor') {
        final st = vendorApprovalStatus ?? 'pending';
        final id = (vendorId ?? '0');
        if (st == 'approved') return '/v/home';
        if (st == 'rejected') return '/v/rejected/$id';
        return '/v/pending/$id';
      }
      if (type == 'admin') return '/a/overview';
    }

    // Role-based area protection
    if (type == 'customer') {
      if (isVendorArea || isAdminArea) return '/c/home';
      return null;
    }

    if (type == 'admin') {
      if (!isAdminArea) return '/a/overview';
      return null;
    }

    if (type == 'vendor') {
      final st = vendorApprovalStatus ?? 'pending';
      final id = (vendorId ?? '0');

      // Vendor can't enter customer/admin areas
      if (isCustomerArea || isAdminArea) {
        // If vendor is approved, send to /v/home; else to status page
        if (st == 'approved') return '/v/home';
        if (st == 'rejected') return '/v/rejected/$id';
        return '/v/pending/$id';
      }

      // Vendor approval gating
      if (st == 'approved') return null;

      if (st == 'rejected') {
        final target = '/v/rejected/$id';
        if (loc != target && !loc.startsWith('/v/rejected')) return target;
        return null;
      }

      // pending
      final target = '/v/pending/$id';
      if (loc != target && !loc.startsWith('/v/pending')) return target;
      return null;
    }

    // Unknown role fallback
    return '/role';
  }
}

final sessionNotifierProvider = Provider<SessionNotifier>((ref) {
  final n = SessionNotifier(ref);
  ref.onDispose(n.dispose);
  return n;
});
