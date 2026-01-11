import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_models.dart';
import '../data/admin_seed.dart';

final adminPricingProvider = StateNotifierProvider<AdminPricingController, List<PricingRow>>((ref) {
  return AdminPricingController()..seed();
});

class AdminPricingController extends StateNotifier<List<PricingRow>> {
  AdminPricingController() : super(const []);

  void seed() => state = [...seedPricing];

  void update(String serviceId, {int? baseKg, int? basePrice, int? excessPerKg}) {
    state = [
      for (final r in state)
        if (r.serviceId == serviceId) r.copyWith(baseKg: baseKg, basePrice: basePrice, excessPerKg: excessPerKg) else r
    ];
  }
}
