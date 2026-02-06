import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/order_tracking_providers.dart';

class OrderMatchingScreen extends ConsumerWidget {
  const OrderMatchingScreen({super.key});

  static const String _pickupScheduledKey = 'pickup_scheduled';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If not set yet, use a dev fallback to test quickly.
    // Later: set this from Review screen after POST /customer/orders.
    final orderId = ref.watch(currentOrderIdProvider) ?? 8;

    final asyncOrder = ref.watch(
      orderPollingProvider((orderId: orderId, interval: matchingPollInterval)),
    );

    ref.listen(
      orderPollingProvider((orderId: orderId, interval: matchingPollInterval)),
      (prev, next) {
        final data = next.valueOrNull;
        if (data == null) return;

        final current = data.timeline.current;

        // Navigate to tracking once pickup is scheduled (vendor accepted)
        if (current == _pickupScheduledKey ||
            current == 'picked_up' ||
            current == 'washing' ||
            current == 'ready' ||
            current == 'out_for_delivery' ||
            current == 'delivered' ||
            current == 'completed') {
          context.go('/c/order/tracking');
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Finding Partner')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: asyncOrder.when(
            loading: () => const _MatchingBody(
              title: 'Finding the best laundry partner near you…',
              subtitle: 'This usually takes a few seconds.',
              showSpinner: true,
            ),
            error: (e, _) => _MatchingBody(
              title: 'Unable to check order status',
              subtitle: e.toString(),
              showSpinner: false,
              trailing: ElevatedButton(
                onPressed: () => ref.invalidate(
                  orderPollingProvider((orderId: orderId, interval: matchingPollInterval)),
                ),
                child: const Text('Retry'),
              ),
            ),
            data: (dto) => _MatchingBody(
              title: 'Finding the best laundry partner near you…',
              subtitle: 'Current: ${dto.timeline.current}',
              showSpinner: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchingBody extends StatelessWidget {
  const _MatchingBody({
    required this.title,
    required this.subtitle,
    required this.showSpinner,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool showSpinner;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) const CircularProgressIndicator(),
        if (showSpinner) const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        if (trailing != null) ...[
          const SizedBox(height: 14),
          trailing!,
        ],
      ],
    );
  }
}
