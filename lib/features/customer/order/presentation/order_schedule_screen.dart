import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/order_models.dart';
import '../state/order_draft_controller.dart';
import 'widgets/section_title.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderScheduleScreen extends ConsumerWidget {
  const OrderScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final ctrl = ref.read(orderDraftProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Pickup & Delivery')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Pickup'),
              _ChoiceTile(title: 'ASAP (Today)', subtitle: 'We’ll arrange pickup soonest available', selected: draft.pickupOption == PickupOption.asap, onTap: () => ctrl.setPickupOption(PickupOption.asap)),
              _ChoiceTile(title: 'Tomorrow', subtitle: 'Next-day pickup', selected: draft.pickupOption == PickupOption.tomorrow, onTap: () => ctrl.setPickupOption(PickupOption.tomorrow)),
              _ChoiceTile(title: 'Schedule', subtitle: 'Pick a specific time (UI placeholder)', selected: draft.pickupOption == PickupOption.scheduled, onTap: () => ctrl.setPickupOption(PickupOption.scheduled)),
              const SizedBox(height: 18),
              const SectionTitle('Delivery'),
              _ChoiceTile(title: 'Pickup & Deliver', subtitle: 'We deliver back to you', selected: draft.deliveryOption == DeliveryOption.pickupAndDeliver, onTap: () => ctrl.setDeliveryOption(DeliveryOption.pickupAndDeliver)),
              _ChoiceTile(title: 'Walk-in', subtitle: 'Bring and pick up yourself (cheaper)', selected: draft.deliveryOption == DeliveryOption.walkIn, onTap: () => ctrl.setDeliveryOption(DeliveryOption.walkIn)),
              const SizedBox(height: 18),
              const SectionTitle('Address'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(draft.addressLabel),
                  subtitle: const Text('Tap to set (UI placeholder)'),
                  leading: const Icon(Icons.location_on_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ctrl.setAddressLabel('Home • (Set later)'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: 'Estimated total: ₱ ${draft.total}',
              subtitle: 'Includes delivery + service fee (placeholder)',
              buttonText: 'Review',
              onPressed: () => context.push('/c/order/review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.title, required this.subtitle, required this.selected, required this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
        onTap: onTap,
      ),
    );
  }
}
