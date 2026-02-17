import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/latest_orders_provider.dart';
import '../../../../core/network/api_client.dart';

/// ===== Weight Review Page =====
/// Called when order status is `weight_reviewed`.
/// - Shows actual/proposed weight + photos
/// - Customer can accept weight (moves order to `weight_accepted`)
/// - After success: refresh orders list, then return to Orders tab
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
  late final Future<Map<String, dynamic>?> _orderFuture;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrder();
  }

  Future<Map<String, dynamic>?> _fetchOrder() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.get('/api/v1/customer/orders/${widget.orderId}');
      final data = (res.data as Map?)?['data'];
      return data is Map ? Map<String, dynamic>.from(data as Map) : null;
    } catch (_) {
      return null;
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return 0;
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatKg(dynamic v) {
    final d = _toDouble(v);
    if (d <= 0) return '-';
    // show 1 decimal (e.g. 7.2 kg)
    return '${d.toStringAsFixed(1)} kg';
  }

  /// Tries multiple common keys to find the reviewed weight.
  /// Adjust to match your backend payload if needed.
  double _reviewedWeightKg(Map<String, dynamic> data) {
    final candidates = [
      data['actual_weight_kg'],
      data['actual_weight'],
      data['reviewed_weight_kg'],
      data['reviewed_weight'],
      data['weight_kg'],
      data['weight'],
      data['actual_weight_value'],
    ];

    for (final c in candidates) {
      final d = _toDouble(c);
      if (d > 0) return d;
    }
    return 0;
  }

  /// Tries multiple common keys for photos list.
  /// Accepts: List<String>, or List<Map> with url fields.
  List<String> _weightPhotoUrls(Map<String, dynamic> data) {
    final rawCandidates = [
      data['weight_photos'],
      data['weight_photo_urls'],
      data['actual_weight_photos'],
      data['actual_weight_photo_urls'],
      data['photos'], // fallback, if you reuse generic photos
    ];

    dynamic raw;
    for (final c in rawCandidates) {
      if (c != null) {
        raw = c;
        break;
      }
    }

    if (raw is! List) return const [];

    final urls = <String>[];
    for (final e in raw) {
      if (e is String && e.trim().isNotEmpty) {
        urls.add(e.trim());
        continue;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final u = (m['url'] ?? m['photo_url'] ?? m['image_url'] ?? m['path'])?.toString();
        if (u != null && u.trim().isNotEmpty) urls.add(u.trim());
      }
    }

    return urls;
  }

  Future<void> _acceptWeight(Map<String, dynamic> order) async {
    if (_submitting) return;

    final status = (order['status'] ?? '').toString().toLowerCase();

    // Optional guard (keep it gentle)
    if (status.isNotEmpty && status != 'weight_reviewed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This order is not ready for weight review (status: $status).')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final client = ref.read(apiClientProvider);

      // ✅ Adjust this endpoint to match your backend route
      // Suggested: POST /api/v1/customer/orders/{order}/approve-final
      await client.dio.post('/api/v1/customer/orders/${widget.orderId}/approve-final');

      if (!mounted) return;

      // Refresh list so Orders tab updates immediately
      try {
        await ref.read(latestOrdersProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight accepted successfully.')),
      );

      // ✅ Return to Orders tab
      if (context.canPop()) {
        Navigator.of(context).pop(true); // return a "success" flag if you want
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Failed to load image'),
                    ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Review'),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _orderFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data;
            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load order details.'),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _orderFuture = _fetchOrder();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reviewedKg = _reviewedWeightKg(data);
            final photoUrls = _weightPhotoUrls(data);

            // Vendor / shop name (same approach as your feedback page)
            final shopRaw = (data['vendor_shop'] as Map?) ??
                (data['accepted_shop'] as Map?) ??
                (data['shop'] as Map?);
            final shop = shopRaw == null ? null : Map<String, dynamic>.from(shopRaw);
            final shopName = shop?['name']?.toString();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                // ---------- HEADER CARD ----------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${data['id'] ?? widget.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shopName?.isNotEmpty == true ? shopName! : 'Vendor',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Status', (data['status'] ?? '-').toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ---------- WEIGHT DETAILS CARD ----------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reviewed Weight',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow('Actual Weight', reviewedKg > 0 ? '${reviewedKg.toStringAsFixed(1)} kg' : '-'),
                      // Optional fields (if your backend has them)
                      if ((data['estimated_weight'] ?? data['estimated_weight_kg']) != null)
                        _infoRow('Estimated Weight', _formatKg(data['estimated_weight'] ?? data['estimated_weight_kg'])),

                      if (data['weight_note'] != null && data['weight_note'].toString().trim().isNotEmpty)
                        _infoRow('Vendor Note', data['weight_note'].toString().trim()),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ---------- PHOTOS ----------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weight Photos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _photoGrid(photoUrls),
                      if (photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Tap any photo to zoom.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // ---------- BOTTOM ACTIONS ----------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _orderFuture,
            builder: (context, snap) {
              final data = snap.data;
              final canAccept = !_submitting && (data != null);

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (context.canPop()) {
                                Navigator.of(context).pop(false);
                              } else {
                                context.go('/c/orders');
                              }
                            },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canAccept ? () => _acceptWeight(data!) : null,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Accept Weight'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
