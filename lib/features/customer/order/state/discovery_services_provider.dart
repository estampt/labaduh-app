import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_service_models.dart';
import 'order_draft_controller.dart';
import 'order_providers.dart';

/// ✅ Only refetch when lat/lng/radius change (NOT when services/pickup/delivery changes)
final discoveryServicesProvider = FutureProvider<List<DiscoveryServiceRow>>((ref) async {
  final loc = ref.watch(
    orderDraftControllerProvider.select(
      (d) => (lat: d.lat, lng: d.lng, radiusKm: d.radiusKm),
    ),
  );

  final api = ref.watch(customerOrdersApiProvider);

  return api.discoveryServices(
    lat: loc.lat,
    lng: loc.lng,
    radiusKm: loc.radiusKm,
  );
});
