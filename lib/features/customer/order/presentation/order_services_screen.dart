import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/services_catalog.dart';
import '../domain/order_models.dart';
import '../state/order_draft_controller.dart';
import 'widgets/kg_stepper.dart';
import 'widgets/section_title.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderServicesScreen extends ConsumerWidget {
  const OrderServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final ctrl = ref.read(orderDraftProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Services')),
      body: Stack(
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

              ...servicesCatalog.map((service) {
                final selectedQty = ctrl.qtyFor(service.id);
                final isSelected = selectedQty > 0;

                final qty = isSelected ? selectedQty : service.baseQty;
                final unit = service.unitType == UnitType.kilo ? 'KG' : 'pc';

                // price estimate per service
                final tempSelection = ServiceSelection(service: service, qty: qty);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(service.icon ?? '🧺', style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text('Base: ${service.baseQty} $unit',
                                        style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isSelected,
                                onChanged: (v) {
                                  if (v) {
                                    ctrl.setServiceQty(service, service.baseQty);
                                  } else {
                                    ctrl.removeService(service.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₱ ${tempSelection.price}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              KgStepper(
                                value: qty,
                                min: service.baseQty,
                                suffix: unit,
                                onChanged: (newQty) => ctrl.setServiceQty(service, newQty),
                              ),
                            ],
                          ),
                          if (service.excessPerUnit > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Excess: ₱ ${service.excessPerUnit} per extra $unit',
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

          // Sticky bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: '${draft.selections.length} service(s) selected',
              subtitle: draft.selections.isEmpty ? 'Select at least 1 service' : 'Estimated: ₱ ${draft.subtotal}',
              buttonText: 'Continue',
              enabled: draft.selections.isNotEmpty,
              onPressed: () => context.go('/c/order/schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
