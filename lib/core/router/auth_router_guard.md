# Optional: GoRouter role/approval guard (recommended)

Your signup now stores:
- auth_token
- auth_user_type (customer/vendor/admin if you support)
- vendor_approval_status (pending/approved/rejected)
- vendor_id

You can add a `redirect:` to your GoRouter to prevent vendors from opening `/v/*` when not approved.

Pseudo-code:

```dart
redirect: (context, state) async {
  final token = await tokenStore.readToken();
  final userType = await tokenStore.readUserType();
  final approval = await tokenStore.readVendorApprovalStatus();

  final loc = state.matchedLocation;
  final isVendorArea = loc.startsWith('/v');
  final isCustomerArea = loc.startsWith('/c');
  final isAdminArea = loc.startsWith('/a');

  if (token == null || token.isEmpty) {
    // allow public routes: /, /role, /login, /signup
    return null;
  }

  if (isVendorArea) {
    if (userType != 'vendor') return '/c/home';
    if (approval == 'pending') return '/v/pending/${await tokenStore.readVendorId() ?? '0'}';
    if (approval == 'rejected') return '/v/rejected/${await tokenStore.readVendorId() ?? '0'}';
  }

  return null;
},
```

Because redirect can't easily be async in pure GoRouter without a refreshListenable,
most teams implement a small `ChangeNotifier` that loads the session once and then
redirect synchronously. If you want, upload your current `app_router.dart` and I will
patch it cleanly for you (ZIP overwrite).
