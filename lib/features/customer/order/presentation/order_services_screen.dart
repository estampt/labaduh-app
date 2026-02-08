import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/service_icons.dart';

import '../models/discovery_service_models.dart';
import '../state/discovery_services_provider.dart';
import '../state/order_draft_controller.dart';

import 'widgets/kg_stepper.dart';
import 'widgets/section_title.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderServicesScreen extends ConsumerWidget {
  const OrderServicesScreen({super.key});

  String _unitLabelFromBaseUnit(String baseUnit) {
    final u = baseUnit.toLowerCase().trim();
    return (u == 'kg' || u == 'kilo' || u == 'kilogram') ? 'KG' : 'pc';
  }

  num _estimatePriceForRow(DiscoveryServiceRow row, num qty) {
    // same logic as DraftSelectedService.computedPrice (using MIN values)
    final minQ = row.baseQty;
    final minPrice = row.basePriceMin;
    final per = row.excessPriceMin;

    if (qty <= minQ) return minPrice;
    return minPrice + ((qty - minQ) * per);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftControllerProvider);
    final ctrl = ref.read(orderDraftControllerProvider.notifier);

    final discoveryAsync = ref.watch(discoveryServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Services')),
      body: discoveryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading services: $e')),
        data: (rows) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  const SectionTitle('What should we wash?'),
                  const Text(
                    'You can choose multiple services. Each service has its own KG/pieces.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  ...rows.map((row) {
                    final serviceId = row.service.id;
                    final isSelected = ctrl.isSelected(row.serviceId);

                    // find selected qty from draft (if selected)
                    final selected = draft.services
                        .where((e) => e.row.serviceId == row.serviceId)
                        .toList();

                    final int qty = isSelected 
                    ? selected.first.qty.toInt() 
                    : row.baseQty.toInt();

                    final unit = _unitLabelFromBaseUnit(row.service.baseUnit);
                    final price = isSelected
                        ? selected.first.computedPrice
                        : _estimatePriceForRow(row, qty);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ServiceIcons.resolve(row.service.icon),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.service.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Base: ${row.baseQty} $unit',
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isSelected,
                                    onChanged: (_) => ctrl.toggleService(row),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱ $price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  KgStepper(
                                    value: qty,
                                    min: row.baseQty,
                                    suffix: unit,
                                    onChanged: (newQty) => ctrl.setQty(row.serviceId, newQty),
                                  ),
                                ],
                              ),
                              if (row.excessPriceMin > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Excess: ₱ ${row.excessPriceMin} per extra $unit',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: StickyBottomBar(
                  title: '${draft.services.length} service(s) selected',
                  subtitle: draft.services.isEmpty
                      ? 'Select at least 1 service'
                      : 'Estimated: ₱ ${draft.subtotal}',
                  buttonText: 'Continue',
                  enabled: draft.services.isNotEmpty,
                  onPressed: () => context.push('/c/order/schedule'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
