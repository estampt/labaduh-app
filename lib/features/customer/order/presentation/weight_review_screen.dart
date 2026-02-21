import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:labaduh/core/network/api_client.dart'; 
import 'package:labaduh/features/customer/order/models/customer_order_model.dart';

import '../data/customer_orders_api.dart';

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
  late Future<CustomerOrder?> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchOrder();
  }

  Future<CustomerOrder?> _fetchOrder() async {
    try {
      final client = ref.read(apiClientProvider);
      final api = CustomerOrdersApi(client.dio);

      final res = await api.getOrderById(
        orderId: widget.orderId,
        category: 'weight_review',
      );

      return res.data.isNotEmpty ? res.data.first : null;
    } catch (e) {
      debugPrint('❌ getOrderById failed: $e');
      return null;
    }
  }

  // ---------------- helpers ----------------
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _money(CustomerOrder o, dynamic amount) {
    final code = o.currencyCode.trim();
    final v = _toDouble(amount);
    return '$code ${v.toStringAsFixed(2)}';
  }

  String _dateShort(String iso) {
    if (iso.isEmpty) return '-';
    final s = iso.replaceAll('T', ' ');
    return s.length >= 16 ? s.substring(0, 16) : s;
  }

  String _qtyLabel(CustomerOrderItem item) {
    final uom = (item.uom ?? '').trim();
    final v = item.qtyActual ?? item.qtyEstimated ?? item.qty;
    final numVal = _toDouble(v);
    if (uom.isEmpty) return numVal.toStringAsFixed(1);
    return '${numVal.toStringAsFixed(1)} ${uom.toUpperCase()}';
  }

  String _itemPriceLabel(CustomerOrder o, CustomerOrderItem item) {
    final v = _toDouble(item.displayPrice);
    return _money(o, v);
  }

  String _optionPriceLabel(CustomerOrder o, CustomerOrderItemOption op) {
    final v = _toDouble(op.displayPrice);
    return _money(o, v);
  }

  List<String> _photoUrls(CustomerOrder order) {
    return order.mediaAttachments
        .where((m) =>
            (m.category ?? '').toLowerCase() == 'weight_review' &&
            (m.url ?? '').trim().isNotEmpty)
        .map((m) => m.url!.trim())
        .toList();
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStrip(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text('No photos attached.'),
      );
    }

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final url = urls[i];
          return InkWell(
            onTap: () => _openImageViewer(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmWeight(
  BuildContext context,
  WidgetRef ref,
  CustomerOrder order,
) async {
  final rootNav = Navigator.of(context, rootNavigator: true);

  /// ✅ 1) Confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm weight'),
      content: const Text('Do you want to confirm the reviewed weight?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('CONFIRM'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  bool loadingShown = false;

  /// ✅ 2) Show loading popup
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Confirming weight...'),
        ],
      ),
    ),
  );

  loadingShown = true;

  try {
    /// ✅ 3) API call
    final client = ref.read(apiClientProvider);
    final api = CustomerOrdersApi(client.dio);

    await api.weightAccepted(order.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weight confirmed.')),
    );

    /// ✅ 4) Small delay so user sees loading
    await Future.delayed(const Duration(milliseconds: 600));

    if (!context.mounted) return;

    /// ✅ 5) Close loading first, then go back to previous screen
    if (loadingShown && rootNav.canPop()) {
      rootNav.pop(); // closes the loading dialog
      loadingShown = false;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true); // return to previous screen (optionally with result)
    }
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e')),
    );
  } finally {
    /// ✅ ALWAYS close loading popup (if still open)
    if (loadingShown && context.mounted && rootNav.canPop()) {
      rootNav.pop();
    }
  }
}

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Weight Review'),
        backgroundColor: const Color(0xFFF3F4F8),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<CustomerOrder?>(
          future: _future,
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
                      const Text('Unable to load order.'),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => setState(() => _future = _fetchOrder()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final shop = order.partner;
            final shopName = (shop?.name ?? 'Laundry Partner').trim();
            final rating = shop?.avgRating;
            final reviews = shop?.ratingsCount;
            final dist = shop?.distanceKm;

            final created = _dateShort(order.createdAt);
            final notes = (order.notes ?? '').trim();
            final photos = _photoUrls(order);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                // ============================================================
                // PARTNER CARD
                // ============================================================
                _RoundedCard(
                  radius: radius,
                  child: ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.local_laundry_service, color: Colors.black54),
                    ),
                    title: Text(
                      shopName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '⭐ ${rating?.toStringAsFixed(1) ?? '-'} • ${reviews ?? 0} reviews • ${dist?.toStringAsFixed(2) ?? '-'} km away',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onTap: () {},
                  ),
                ),

                const SizedBox(height: 10),

                // ============================================================
                // ITEMS CARD
                // ============================================================
                _RoundedCard(
                  radius: radius,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Text(
                            _money(order, order.totalAmount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Order placed',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            Text(
                              created,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
                        const SizedBox(height: 12),

                        ...order.items.map((item) {
                          final title =
                              (item.service?.name ?? item.serviceId.toString()).trim();
                          final qty = _qtyLabel(item);
                          final price = _itemPriceLabel(order, item);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Text(
                                      price,
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Qty: $qty',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),

                                if (item.options.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add-ons',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black54,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...item.options.map((op) {
                                    final name = (op.displayName ?? 'Option').trim();
                                    final req = (op.isRequired == true) ? ' (required)' : '';
                                    final opPrice = _optionPriceLabel(order, op);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$name$req',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Text(
                                            opPrice,
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 22),

                        _AmountRow(label: 'Subtotal', valueText: _money(order, order.subtotalAmount)),
                        _AmountRow(label: 'Delivery Fee', valueText: _money(order, order.deliveryFeeAmount)),
                        _AmountRow(label: 'Service Fee', valueText: _money(order, order.serviceFeeAmount)),
                        _AmountRow(label: 'Discount', valueText: _money(order, -order.discountAmount)),

                        const SizedBox(height: 6),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.25)),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
                            Text(_money(order, order.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ============================================================
                // ✅ PHOTOS OUTSIDE THE ITEMS CARD
                // ============================================================
                _RoundedCard(
                  radius: radius,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attached Photos',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        _photoStrip(photos),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ============================================================
                // ✅ NOTES OUTSIDE THE ITEMS CARD
                // ============================================================
                _RoundedCard(
                  radius: radius,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Text(
                          notes.isEmpty ? 'No notes.' : notes,
                          style: TextStyle(
                            color: notes.isEmpty ? Colors.black54 : Colors.black87,
                            height: 1.35,
                            fontWeight: notes.isEmpty ? FontWeight.w600 : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FutureBuilder<CustomerOrder?>(
            future: _future,
            builder: (_, snap) {
              final order = snap.data;
              final disabled = _submitting || order == null;

              return SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disabled ? null : () => _confirmWeight(context, ref, order),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Confirm Weight',
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

// ============================================================
// Shared Widgets
// ============================================================

class _RoundedCard extends StatelessWidget {
  const _RoundedCard({
    required this.radius,
    required this.child,
  });

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.valueText,
  });

  final String label;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            valueText,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}