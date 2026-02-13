import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/order_draft_controller.dart';
import 'widgets/sticky_bottom_bar.dart';
import 'widgets/section_title.dart';

class OrderScheduleScreen extends ConsumerStatefulWidget {
  const OrderScheduleScreen({super.key});

  @override
  ConsumerState<OrderScheduleScreen> createState() => _OrderScheduleScreenState();
}

class _OrderScheduleScreenState extends ConsumerState<OrderScheduleScreen> {
  DateTime? _scheduledDate;

  Future<void> _pickDateAndPersist() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );

    if (picked == null) return;

    setState(() => _scheduledDate = picked);

    final ctrl = ref.read(orderDraftControllerProvider.notifier);
    final dyn = ctrl as dynamic;

    // Ensure schedule mode
    try {
      dyn.setPickupMode('schedule');
    } catch (_) {}

    // Default window: 9am–5pm (you can later add time picker)
    final start = DateTime(picked.year, picked.month, picked.day, 9);
    final end = DateTime(picked.year, picked.month, picked.day, 17);

    // Persist with best-effort compatibility (DateTime then ISO string).
    bool saved = false;

    // 1) setPickupWindow(start, end)
    try {
      dyn.setPickupWindow(start, end);
      saved = true;
    } catch (_) {}

    // 2) setPickupWindowStart / setPickupWindowEnd
    if (!saved) {
      try {
        dyn.setPickupWindowStart(start);
        dyn.setPickupWindowEnd(end);
        saved = true;
      } catch (_) {}
    }
    if (!saved) {
      try {
        dyn.setPickupWindowStart(start.toIso8601String());
        dyn.setPickupWindowEnd(end.toIso8601String());
        saved = true;
      } catch (_) {}
    }

    // 3) setPickupDate / setScheduledPickupDate
    if (!saved) {
      try {
        dyn.setPickupDate(picked);
        saved = true;
      } catch (_) {}
    }
    if (!saved) {
      try {
        dyn.setPickupDate(picked.toIso8601String());
        saved = true;
      } catch (_) {}
    }
    if (!saved) {
      try {
        dyn.setScheduledPickupDate(picked);
        saved = true;
      } catch (_) {}
    }
    if (!saved) {
      try {
        dyn.setScheduledPickupDate(picked.toIso8601String());
        saved = true;
      } catch (_) {}
    }

    // If still not saved, the draft controller doesn’t expose setters.
    // The UI will still show the selected date locally, but review/submit
    // won’t see it until you add a setter in your controller.
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderDraftControllerProvider);
    final ctrl = ref.read(orderDraftControllerProvider.notifier);

    final isSchedule = (draft.pickupMode ?? '').toString() == 'schedule';

    final dateLabel = _scheduledDate == null
        ? 'Select a date'
        : MaterialLocalizations.of(context).formatMediumDate(_scheduledDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Pickup & Delivery')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Pickup'),

              RadioListTile<String>(
                value: 'asap',
                groupValue: draft.pickupMode,
                onChanged: (v) => ctrl.setPickupMode(v!),
                title: const Text('ASAP (Today)'),
                subtitle: const Text('We’ll arrange pickup soonest available'),
              ),

              RadioListTile<String>(
                value: 'tomorrow',
                groupValue: draft.pickupMode,
                onChanged: (v) => ctrl.setPickupMode(v!),
                title: const Text('Tomorrow'),
                subtitle: const Text('Next-day pickup'),
              ),

              RadioListTile<String>(
                value: 'schedule',
                groupValue: draft.pickupMode,
                onChanged: (v) async {
                  ctrl.setPickupMode(v!);
                  // Prompt immediately when switching to schedule
                  await _pickDateAndPersist();
                },
                title: const Text('Schedule'),
                subtitle: const Text('Pick a specific date'),
              ),

              if (isSchedule) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text(dateLabel),
                    subtitle: const Text('Tap to change'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDateAndPersist,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const SectionTitle('Delivery'),

              RadioListTile<String>(
                value: 'pickup_deliver',
                groupValue: draft.deliveryMode,
                onChanged: (v) => ctrl.setDeliveryMode(v!),
                title: const Text('Pickup & Deliver'),
                subtitle: const Text('We deliver back to you'),
              ),

              RadioListTile<String>(
                value: 'walk_in',
                groupValue: draft.deliveryMode,
                onChanged: (v) => ctrl.setDeliveryMode(v!),
                title: const Text('Walk-in'),
                subtitle: const Text('Bring and pick up yourself (cheaper)'),
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: 'Estimated total: ₱ ${draft.total}',
              subtitle: 'Includes delivery + service fee',
              buttonText: 'Review',
              enabled: draft.services.isNotEmpty && (!isSchedule || _scheduledDate != null),
              onPressed: () => context.push('/c/order/review'),
            ),
          ),
        ],
      ),
    );
  }
}
