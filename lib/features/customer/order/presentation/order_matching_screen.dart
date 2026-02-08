import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/latest_orders_provider.dart';
import '../data/customer_orders_api.dart';
import '../../../../core/network/api_client.dart';

// TODO: move these helper files into your lib/ and fix the import path to match.
import '../../../../core/utils/pick_image.dart';

class OrderMatchingScreen extends ConsumerStatefulWidget {
  final String? flashMessage;
  const OrderMatchingScreen({super.key, this.flashMessage});

  @override
  ConsumerState<OrderMatchingScreen> createState() => _OrderMatchingScreenState();
}

class _OrderMatchingScreenState extends ConsumerState<OrderMatchingScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();

    final msg = widget.flashMessage;
    if (msg != null && msg.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      });
    }

    // Light polling so statuses refresh (published -> picked_up -> washing etc.)
    _poll = Timer.periodic(const Duration(seconds: 120), (_) {
      ref.read(latestOrdersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(latestOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders: $e')),
        data: (state) {
          // ✅ show ALL active orders (stacked). User scrolls if many.
          final orders = state.orders.toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No active orders right now.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(latestOrdersProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];

                // Map API status to the 5-step tracking design
                final statusKey = normalizeTrackingStatus(o.status);
                final activeIndex = trackingIndexFromStatus(statusKey);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _OrderTrackingCard(
                    orderId: o.id,
                    statusKey: statusKey,
                    activeIndex: activeIndex,
                    // optional: show a small subtext like pricing status if you want later
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// ===== Tracking design (matches the attached UI) =====
/// Steps shown:
/// Pickup scheduled -> Picked up -> Washing -> Ready -> Delivered
const _trackingSteps = <String>[
  'pickup_scheduled',
  'picked_up',
  'washing',
  'ready',
  'delivered',
];

/// Normalize backend statuses into the 5-step UI.
/// Extend this map as your backend evolves.
String normalizeTrackingStatus(String status) {
  final s = status.toLowerCase().trim();

  // Early pipeline statuses -> before pickup scheduled
  if (s == 'published' || s == 'order_created' || s == 'broadcasting' || s == 'matching') {
    return 'pickup_scheduled';
  }

  // Some backends may use these keys
  if (s == 'out_for_delivery') return 'ready';
  if (s == 'completed') return 'delivered';

  // If backend already returns one of our keys
  if (_trackingSteps.contains(s)) return s;

  // Default
  return 'pickup_scheduled';
}

int trackingIndexFromStatus(String statusKey) {
  final idx = _trackingSteps.indexOf(statusKey);
  return idx < 0 ? 0 : idx;
}

String trackingLabel(String key) {
  switch (key) {
    case 'pickup_scheduled':
      return 'Pickup scheduled';
    case 'picked_up':
      return 'Picked up';
    case 'washing':
      return 'Washing';
    case 'ready':
      return 'Ready';
    case 'delivered':
      return 'Delivered';
    default:
      return key;
  }
}

class _OrderTrackingCard extends ConsumerStatefulWidget {
  final int orderId;
  final String statusKey; // normalized
  final int activeIndex; // 0..4

  const _OrderTrackingCard({
    required this.orderId,
    required this.statusKey,
    required this.activeIndex,
  });

  @override
  ConsumerState<_OrderTrackingCard> createState() => _OrderTrackingCardState();
}

class _OrderTrackingCardState extends ConsumerState<_OrderTrackingCard> {
  bool _submitting = false;

  bool get _isDelivered => widget.statusKey == 'delivered';

  Future<void> _confirmDelivery() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final client = ref.read(apiClientProvider);

      final ordersApi = CustomerOrdersApi(client.dio);
      await ordersApi.confirmDelivery(widget.orderId);
// If needed later: parse res.data['data'] and update local state.
      // For now: refresh list and go to feedback page placeholder.
      if (mounted) {
        await ref.read(latestOrdersProvider.notifier).refresh();
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderCommentsScreen(
              orderId: widget.orderId,
              showOrderCompletedMessage: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete order: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.orderId}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Status updates (UI placeholder)',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // ✅ The "old" design list
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _trackingSteps.length; i++) ...[
                  _TrackingRow(
                    label: trackingLabel(_trackingSteps[i]),
                    done: i <= widget.activeIndex,
                    isFirst: i == 0,
                  ),
                  if (i != _trackingSteps.length - 1)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD7DBE8)),
                ],
              ],
            ),
          ),

          // ✅ Complete order button only when delivered
          if (_isDelivered) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E5A8C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool isFirst;

  const _TrackingRow({
    required this.label,
    required this.done,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final icon = done ? Icons.check_circle : Icons.radio_button_unchecked;
    final color = done ? Colors.black87 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: done ? Colors.black87 : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== Comments & Suggestions Page (Web-ready, with optional image) =====
/// After order completion, route here to collect feedback.
/// - Passes order number
/// - Allows attaching a photo (web file upload) and previewing it
class OrderCommentsScreen extends ConsumerStatefulWidget {
  final int orderId;
  final bool showOrderCompletedMessage;

  const OrderCommentsScreen({
    super.key,
    required this.orderId,
    this.showOrderCompletedMessage = false,
  });

  @override
  ConsumerState<OrderCommentsScreen> createState() => _OrderCommentsScreenState();
}

class _OrderCommentsScreenState extends ConsumerState<OrderCommentsScreen> {
  final _commentCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOrderCompletedMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order completed. Please leave a review.')),
        );
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bytes = await pickImageBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

   Future<void> _submit() async {
  if (_submitting) return;
  setState(() => _submitting = true);

  try {
    // TODO: Replace with real feedback API call
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    // Refresh latest orders
    await ref.read(latestOrdersProvider.notifier).refresh();

    final latest = ref.read(latestOrdersProvider).maybeWhen(
          data: (s) => s,
          orElse: () => null,
        );

    final remainingCount = latest?.orders.length ?? 0;

    const msg = 'Review submitted. Thank you!';

    if (remainingCount > 0) {
      // Go back to Order Matching and return success message
      GoRouter.of(context).pop(msg);
      return;
    }

    // If no more orders → show success then go home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(msg)),
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    GoRouter.of(context).go('/c/home');
  } finally {
    if (mounted) setState(() => _submitting = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final canUploadImage = kIsWeb; // our helper uses web file input

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Order #${widget.orderId}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Leave comments and suggestions (placeholder)',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _commentCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Comments',
              hintText: 'Tell us what went well or what to improve...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canUploadImage ? _pickImage : null,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(canUploadImage ? 'Add image' : 'Image upload (web only)'),
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => setState(() => _imageBytes = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),

          if (_imageBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E5A8C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
