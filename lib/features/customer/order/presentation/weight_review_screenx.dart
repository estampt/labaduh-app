import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:labaduh/features/customer/order/data/customer_orders_api.dart';
import 'package:labaduh/features/customer/order/models/customer_order_model.dart';

import '../state/latest_orders_provider.dart';
import '../../../../core/network/api_client.dart';

// ✅ ADD THIS IMPORT (adjust path if your file is elsewhere) 

class WeightReviewScreen extends ConsumerStatefulWidget {
  final int orderId;

  const WeightReviewScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<WeightReviewScreen> createState() => _WeightReviewScreenState();
}

class _WeightReviewScreenState extends ConsumerState<WeightReviewScreen> {
  late Future<CustomerOrder?> _orderFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder();
  }

  Future<CustomerOrder?> _fetchOrder() async {
  try {
    final client = ref.read(apiClientProvider);

    // Call CustomerOrdersApi
    final api = CustomerOrdersApi(client.dio);

    final response = await api.getOrderById(
      orderId: widget.orderId,
      category: 'weight_review', // optional filter
    );

    // Since /by_id returns single object wrapped in list
    if (response.data.isEmpty) return null;

    return response.data.first;
  } catch (e) {
    debugPrint('❌ Failed to fetch order: $e');
    return null;
  }
}

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return 0;
    return double.tryParse(s) ?? 0;
  }

  double _reviewedWeightKg(CustomerOrder order) {
    var sum = 0.0;

    for (final item in order.items) {
      final uom = (item.uom ?? '').toLowerCase();
      if (uom != 'kg') continue;

      final v = item.qtyActual ?? item.qtyEstimated ?? item.qty;
      sum += _asDouble(v);
    }

    return sum;
  }

  String _formatKg(double v) => v > 0 ? '${v.toStringAsFixed(1)} kg' : '-';

  List<String> _weightPhotoUrls(CustomerOrder order) {
    return order.mediaAttachments
        .where((m) =>
            (m.category ?? '').toLowerCase() == 'weight_review' &&
            (m.url ?? '').trim().isNotEmpty)
        .map((m) => m.url!.trim())
        .toList();
  }

  Future<void> _acceptWeight(CustomerOrder order) async {
    if (_submitting) return;

    final status = order.status.toLowerCase();
    if (status.isNotEmpty && status != 'weight_reviewed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This order is not ready for weight review (status: $status).',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = ref.read(apiClientProvider);

      await client.dio.post(
        '/api/v1/customer/orders/${widget.orderId}/approve-final',
      );

      if (!mounted) return;

      // Refresh list so Orders tab updates immediately
      try {
        await ref.read(latestOrdersProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight accepted successfully.')),
      );

      if (context.canPop()) {
        Navigator.of(context).pop(true);
      } else {
        context.go('/c/orders');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept weight: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Text('Failed to load image')),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _photoGrid(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text('No photos provided.'),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final url = urls[index];
        return InkWell(
          onTap: () => _openImageViewer(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black12,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight Review')),
      body: SafeArea(
        child: FutureBuilder<CustomerOrder?>(
          future: _orderFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final order = snap.data;
            if (order == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load order details.'),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => _orderFuture = _fetchOrder()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reviewedKg = _reviewedWeightKg(order);
            final photoUrls = _weightPhotoUrls(order);
            final shopName = order.partner?.name ?? 'Vendor';

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shopName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reviewed Weight: ${_formatKg(reviewedKg)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _photoGrid(photoUrls),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FutureBuilder<CustomerOrder?>(
            future: _orderFuture,
            builder: (_, snap) {
              final order = snap.data;
              final disabled = _submitting || order == null;

              return SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disabled ? null : () => _acceptWeight(order!),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Accept Weight',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}