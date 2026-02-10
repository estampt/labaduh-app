import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
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

    if (!mounted) return;

    // ✅ Navigate FIRST (before refresh can unmount this widget)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderCommentsScreen(
          orderId: widget.orderId,
          showOrderCompletedMessage: true,
        ),
      ),
    );

    // ✅ Refresh AFTER (do not await)
    // ignore: unawaited_futures
    ref.read(latestOrdersProvider.notifier).refresh();
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
  final ImagePicker _picker = ImagePicker();

  late final Future<Map<String, dynamic>?> _orderFuture;

  int _rating = 5;
  bool _submitting = false;

  // Picked images (0..10)
  final List<XFile> _images = [];

  // Upload progress 0..1 (null when not uploading)
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder();

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

  Future<Map<String, dynamic>?> _fetchOrder() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.get('/api/v1/customer/orders/${widget.orderId}');
      final data = (res.data as Map?)?['data'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  void _setRating(int v) => setState(() => _rating = v.clamp(1, 5));

  Future<void> _pickFromGallery() async {
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 10 photos allowed.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;

    final remaining = 10 - _images.length;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 10 photos allowed.')),
      );
      return;
    }

    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (img == null) return;

    setState(() => _images.add(img));
  }

  void _removeAt(int index) => setState(() => _images.removeAt(index));

  Future<void> _submit() async {
    if (_submitting) return;

    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = _images.isEmpty ? null : 0;
    });

    try {
      final client = ref.read(apiClientProvider);
      final api = CustomerOrdersApi(client.dio);

      

      await api.submitFeedbackMultipart(
        orderId: widget.orderId,
        rating: _rating,
        comments: _commentCtrl.text,
        images: _images,
        onSendProgress: _images.isEmpty
            ? null
            : (sent, total) {
                if (total <= 0) return;
                if (!mounted) return;
                setState(() => _uploadProgress = sent / total);
              },
      );
      
      if (!mounted) return;

      // Refresh orders list and decide where to go next.
      bool hasActiveOrders = false;
      try {
        await ref.read(latestOrdersProvider.notifier).refresh();
        hasActiveOrders =
            ref.read(latestOrdersProvider).value?.orders.isNotEmpty ?? false;
      } catch (_) {
        // If refresh fails, fall back to returning to tracking.
        hasActiveOrders = true;
      }

      if (!mounted) return;

      // Give user feedback first (then navigate).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    if (hasActiveOrders) {
      // ✅ Go back to tracking without guessing route
      if (context.canPop()) {
        Navigator.of(context).pop();
      } else {
        // Fallback if no stack
        context.go('/c/order/matching');//context.go('/c/orders'); // keep if your router really uses this
      }
    } else {
      // ✅ No active orders → go home
      context.go('/c/home');
    }
  });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Widget _thumb(XFile img) {
    final r = BorderRadius.circular(10);

    // Web: some builds allow img.path as blob URL; memory is more reliable.
    return ClipRRect(
      borderRadius: r,
      child: FutureBuilder<Uint8List>(
        future: img.readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Container(
              width: 90,
              height: 90,
              alignment: Alignment.center,
              color: Colors.black12,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _buildReorderableThumbs() {
    // Horizontal reorder list (drag to reorder)
    return SizedBox(
      height: 110,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _images.removeAt(oldIndex);
            _images.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final img = _images[index];
          return Container(
            key: ValueKey('img_${img.name}_$index'),
            margin: const EdgeInsets.only(right: 10),
            child: Stack(
              children: [
                _thumb(img),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: () => _removeAt(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orderInfoCard(Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? const [];
    final status = (data['status'] ?? '').toString();
    final pricingStatus = (data['pricing_status'] ?? '').toString();
    final estimatedTotal = data['estimated_total']?.toString();
    final finalTotal = data['final_total']?.toString();
    final total = (finalTotal != null && finalTotal.isNotEmpty) ? finalTotal : (estimatedTotal ?? '-');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${data['id']}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                Chip(label: Text('Status: $status')),
                Chip(label: Text('Pricing: $pricingStatus')),
                Chip(label: Text('Total: $total')),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...items.map((e) {
              final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
              final serviceId = m['service_id']?.toString() ?? '-';
              final qty = m['qty']?.toString() ?? '-';
              final price = m['price']?.toString() ?? '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Service #$serviceId × $qty')),
                    Text(price),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _orderFuture,
              builder: (context, snap) {
                final data = snap.data;
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  );
                }
                if (data == null) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Order #${widget.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  );
                }
                return _orderInfoCard(data);
              },
            ),

            Text(
              'How was your experience?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),

            // ⭐ Yellow stars
            Row(
              children: List.generate(5, (i) {
                final v = i + 1;
                final selected = v <= _rating;
                return IconButton(
                  onPressed: () => _setRating(v),
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border,
                    color: selected ? Colors.amber : Colors.grey,
                  ),
                  iconSize: 32,
                );
              }),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_images.isEmpty)
              const Text('Add up to 10 photos (optional).')
            else ...[
              const Text('Drag to reorder photos (optional).'),
              const SizedBox(height: 8),
              _buildReorderableThumbs(),
            ],

            if (_uploadProgress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 6),
              Text(
                'Uploading: ${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.black54),
              ),
            ],

            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
