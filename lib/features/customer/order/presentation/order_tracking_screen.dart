import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/order_tracking_providers.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = ref.watch(currentOrderIdProvider) ?? 8;

    final asyncOrder = ref.watch(
      orderPollingProvider((orderId: orderId, interval: trackingPollInterval)),
    );

    final pricingAction = ref.watch(pricingDecisionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncOrder.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(
              orderPollingProvider((orderId: orderId, interval: trackingPollInterval)),
            ),
          ),
          data: (dto) {
            final timeline = dto.timeline;

            return ListView(
              children: [
                Text(
                  'Order #${dto.order.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current: ${timeline.current}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),

                // Repricing banner
                if (timeline.requiresCustomerAction) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Final price approval needed',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The laundry partner proposed a final amount. Please approve or reject.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: pricingAction.isLoading
                                      ? null
                                      : () async {
                                          await ref.read(pricingDecisionProvider.notifier).reject(dto.order.id);
                                          ref.invalidate(orderPollingProvider((orderId: orderId, interval: trackingPollInterval)));
                                        },
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: pricingAction.isLoading
                                      ? null
                                      : () async {
                                          await ref.read(pricingDecisionProvider.notifier).approve(dto.order.id);
                                          ref.invalidate(orderPollingProvider((orderId: orderId, interval: trackingPollInterval)));
                                        },
                                  child: pricingAction.isLoading
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (final step in timeline.steps) ...[
                          _TimelineRow(
                            label: step.label,
                            state: step.state,
                          ),
                          if (step.key != timeline.steps.last.key)
                            const Divider(height: 18, thickness: 1),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Optional manual refresh
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                    orderPollingProvider((orderId: orderId, interval: trackingPollInterval)),
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.state});

  final String label;
  final String state; // done/current/todo

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (state == 'done') {
      icon = Icons.check_circle;
    } else if (state == 'current') {
      icon = Icons.radio_button_checked;
    } else {
      icon = Icons.radio_button_unchecked;
    }

    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
