import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/order_draft_controller.dart';
import 'widgets/sticky_bottom_bar.dart';
import 'widgets/section_title.dart';

class OrderScheduleScreen extends ConsumerWidget {
  const OrderScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftControllerProvider);
    final ctrl =
        ref.read(orderDraftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Pickup & Delivery')),
      body: Stack(
        children: [
          ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Pickup'),

              RadioListTile<String>(
                value: 'asap',
                groupValue: draft.pickupMode,
                onChanged: (v) =>
                    ctrl.setPickupMode(v!),
                title: const Text('ASAP (Today)'),
                subtitle: const Text(
                    'We’ll arrange pickup soonest available'),
              ),

              RadioListTile<String>(
                value: 'tomorrow',
                groupValue: draft.pickupMode,
                onChanged: (v) =>
                    ctrl.setPickupMode(v!),
                title: const Text('Tomorrow'),
                subtitle:
                    const Text('Next-day pickup'),
              ),

              RadioListTile<String>(
                value: 'schedule',
                groupValue: draft.pickupMode,
                onChanged: (v) =>
                    ctrl.setPickupMode(v!),
                title: const Text('Schedule'),
                subtitle: const Text(
                    'Pick a specific time (UI placeholder)'),
              ),

              const SizedBox(height: 16),
              const SectionTitle('Delivery'),

              RadioListTile<String>(
                value: 'pickup_deliver',
                groupValue: draft.deliveryMode,
                onChanged: (v) =>
                    ctrl.setDeliveryMode(v!),
                title: const Text('Pickup & Deliver'),
                subtitle:
                    const Text('We deliver back to you'),
              ),

              RadioListTile<String>(
                value: 'walk_in',
                groupValue: draft.deliveryMode,
                onChanged: (v) =>
                    ctrl.setDeliveryMode(v!),
                title: const Text('Walk-in'),
                subtitle: const Text(
                    'Bring and pick up yourself (cheaper)'),
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title:
                  'Estimated total: ₱ ${draft.total}',
              subtitle:
                  'Includes delivery + service fee',
              buttonText: 'Review',
              enabled: draft.services.isNotEmpty,
              onPressed: () =>
                  context.push('/c/order/review'),
            ),
          ),
        ],
      ),
    );
  }
}
