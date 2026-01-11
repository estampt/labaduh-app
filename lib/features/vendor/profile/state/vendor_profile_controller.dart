import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vendor_profile.dart';

final vendorProfileProvider =
    StateNotifierProvider<VendorProfileController, VendorProfile>((ref) {
  return VendorProfileController();
});

class VendorProfileController extends StateNotifier<VendorProfile> {
  VendorProfileController()
      : super(const VendorProfile(
          shopName: 'Labaduh Laundry (Demo)',
          address: 'Quezon City, PH',
          openHours: '9:00 AM – 8:00 PM',
          capacityKgPerDay: 120,
          vacationMode: false,
        ));

  void setVacation(bool v) => state = state.copyWith(vacationMode: v);
  void setShopName(String v) => state = state.copyWith(shopName: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setHours(String v) => state = state.copyWith(openHours: v);
  void setCapacity(int v) => state = state.copyWith(capacityKgPerDay: v);
}
