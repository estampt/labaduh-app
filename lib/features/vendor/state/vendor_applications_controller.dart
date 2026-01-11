import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_role.dart';
import '../data/vendor_application.dart';

final vendorApplicationsProvider =
    StateNotifierProvider<VendorApplicationsController, List<VendorApplication>>((ref) {
  return VendorApplicationsController()..seed();
});

class VendorApplicationsController extends StateNotifier<List<VendorApplication>> {
  VendorApplicationsController() : super(const []);

  void seed() {
    state = [
      VendorApplication(
        id: 'v001',
        ownerName: 'Ana Santos',
        shopName: 'Sparkle Laundry',
        city: 'Quezon City',
        mobile: '0917 000 0000',
        email: 'sparkle@example.com',
        createdAtLabel: 'Today 10:05',
        status: VendorApprovalStatus.pending,
      ),
      VendorApplication(
        id: 'v002',
        ownerName: 'Miguel Cruz',
        shopName: 'QuickWash',
        city: 'Makati',
        mobile: '0917 111 1111',
        email: 'quickwash@example.com',
        createdAtLabel: 'Yesterday',
        status: VendorApprovalStatus.approved,
      ),
      VendorApplication(
        id: 'v003',
        ownerName: 'Aya Tan',
        shopName: 'Bubbles Cleaners',
        city: 'Pasig',
        mobile: '0917 222 2222',
        email: 'bubbles@example.com',
        createdAtLabel: '2 days ago',
        status: VendorApprovalStatus.rejected,
        adminNote: 'Incomplete business permit.',
      ),
    ];
  }

  VendorApplication? byId(String id) => state.where((a) => a.id == id).firstOrNull;

  void submit(VendorApplication app) {
    state = [app, ...state];
  }

  void approve(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: VendorApprovalStatus.approved, adminNote: null) else a
    ];
  }

  void reject(String id, String note) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: VendorApprovalStatus.rejected, adminNote: note) else a
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
