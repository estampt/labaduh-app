import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vendor_pricing.dart';

final vendorPricingProvider =
    StateNotifierProvider<VendorPricingController, VendorPricing>((ref) {
  return VendorPricingController()..seed();
});

class VendorPricingController extends StateNotifier<VendorPricing> {
  VendorPricingController() : super(const VendorPricing(useSystemPricing: true, services: []));

  void seed() {
    state = VendorPricing(
      useSystemPricing: true,
      services: [
        VendorServicePrice(serviceId: 'wash_fold', serviceName: 'Wash & Fold', baseKg: 6, basePrice: 299, excessPerKg: 45),
        VendorServicePrice(serviceId: 'whites', serviceName: 'All Whites', baseKg: 6, basePrice: 319, excessPerKg: 50),
        VendorServicePrice(serviceId: 'colored', serviceName: 'Colored', baseKg: 6, basePrice: 309, excessPerKg: 48),
        VendorServicePrice(serviceId: 'delicates', serviceName: 'Delicates', baseKg: 3, basePrice: 249, excessPerKg: 55),
      ],
    );
  }

  void setUseSystemPricing(bool v) => state = state.copyWith(useSystemPricing: v);

  void updateService(String serviceId, {int? baseKg, int? basePrice, int? excessPerKg}) {
    final updated = state.services.map((s) {
      if (s.serviceId != serviceId) return s;
      return s.copyWith(baseKg: baseKg, basePrice: basePrice, excessPerKg: excessPerKg);
    }).toList();
    state = state.copyWith(services: updated);
  }
}
