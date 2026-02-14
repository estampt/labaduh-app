
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
/// ===== Comments & Suggestions Page (Web-ready, with optional image) =====
/// After order completion, route here to collect feedback.
/// - Passes order number
/// - Allows attaching a photo (web file upload) and previewing it
class OrderFeedbackScreen extends ConsumerStatefulWidget {
  final int orderId;
  final bool showOrderCompletedMessage;

  const OrderFeedbackScreen({
    super.key,
    required this.orderId,
    this.showOrderCompletedMessage = false,
  });

  @override
  ConsumerState<OrderFeedbackScreen> createState() => _OrderFeedbackScreenState();
}

class _OrderFeedbackScreenState extends ConsumerState<OrderFeedbackScreen> {
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

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return 0;
    // Keep digits, minus, and dot only.
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double _computeTotalAmount(Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? const [];
    double total = 0;

    for (final e in items) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);

      final qty = _toDouble(m['qty']);
      final computed = m['computed_price'];
      final price = m['price'];

      // If computed_price exists, treat as line total. Otherwise, price * qty (fallback).
      if (computed != null && computed.toString().toString().isNotEmpty) {
        total += _toDouble(computed);
      } else {
        final unit = _toDouble(price);
        total += unit * (qty > 0 ? qty : 1);
      }

      // Options / add-ons
      final options = (m['options'] as List?) ?? const [];
      for (final o in options) {
        if (o is! Map) continue;
        final om = Map<String, dynamic>.from(o);
        final optQty = _toDouble(om['qty']);
        final optComputed = om['computed_price'];
        final optPrice = om['price'];

        if (optComputed != null && optComputed.toString().isNotEmpty) {
          total += _toDouble(optComputed);
        } else {
          final unit = _toDouble(optPrice);
          total += unit * (optQty > 0 ? optQty : 1);
        }
      }
    }

    return total;
  }

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

      
      WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    if (hasActiveOrders) {
      // ✅ Go back to tracking without guessing route
      if (context.canPop()) {
        Navigator.of(context).pop();
      } else {
        // Fallback if no stack
        context.go('/c/order/tracking');
        // Give user feedback first (then navigate).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted. Thank you!')),
        );

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

    // ✅ Compute total from items + add-ons (fallback if API total is missing/incorrect)
    final computedTotal = _computeTotalAmount(data);

    // Show computed total. If computed is 0 (e.g. missing item prices), fall back to API totals.
    final apiTotal = (data['total']?.toString().isNotEmpty ?? false)
        ? data['total']?.toString()
        : ((data['final_total']?.toString().isNotEmpty ?? false)
            ? data['final_total']?.toString()
            : (data['estimated_total']?.toString() ?? ''));

    final totalLabel = (computedTotal > 0)
        ? computedTotal.toStringAsFixed(2)
        : (apiTotal.toString().trim().isNotEmpty ? apiTotal.toString().trim() : '0.00');

    // Vendor / shop (new JSON uses vendor_shop + accepted_shop)
    final shopRaw = (data['vendor_shop'] as Map?) ?? (data['accepted_shop'] as Map?) ?? (data['shop'] as Map?);
    final shop = shopRaw == null ? null : Map<String, dynamic>.from(shopRaw);

    String? shopName = shop?['name']?.toString();
    final photoUrl = shop?['profile_photo_url']?.toString();
    final avgRating = shop?['avg_rating'];
    final ratingsCount = shop?['ratings_count'];
    final distanceKm = shop?['distance_km'];

    String subtitle = '';
    final parts = <String>[];
    if (avgRating != null && avgRating.toString().isNotEmpty) {
      final r = double.tryParse(avgRating.toString());
      if (r != null) parts.add('⭐ ${r.toStringAsFixed(1)}');
    }
    if (ratingsCount != null) parts.add('($ratingsCount)');
    if (distanceKm != null) {
      final d = double.tryParse(distanceKm.toString());
      if (d != null) parts.add('${d.toStringAsFixed(2)} km away');
    }
    subtitle = parts.isEmpty ? 'Laundry partner' : parts.join(' • ');

    return Column(
      children: [
        // Vendor / partner card (only if available)
        if (shop != null) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: (photoUrl != null && photoUrl.trim().isNotEmpty)
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(photoUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                  : const CircleAvatar(child: Icon(Icons.storefront)),
              title: Text(
                shopName?.trim().isNotEmpty == true ? shopName!.trim() : 'Laundry partner',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(subtitle),
            ),
          ),
        ],

        // Order details card
        // Wrap your existing card with an ExpansionTile layout.
Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    initiallyExpanded: false,

    // 🔽 Collapsed view (default): ONLY Order Number + Price
    title: Row(
      children: [
        Expanded(
          child: Text(
            'Order #${data['id']}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        Text(
          '₱ $totalLabel',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    ),

    // Optional: small hint line under title (remove if you want it even cleaner)
    subtitle: Text(
      '${items.length} service${items.length == 1 ? '' : 's'}',
      style: const TextStyle(color: Colors.black54),
    ),

    // 🔼 Expanded content: EVERYTHING ELSE goes here (the "middle")
    children: [
      //const SizedBox(height: 10),
      //const Text('Services', style: TextStyle(fontWeight: FontWeight.w800)),
      //const SizedBox(height: 8),

      ...items.map((e) {
        final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};

        final service = (m['service'] is Map) ? Map<String, dynamic>.from(m['service']) : null;
        final serviceName = service?['name']?.toString();
        final serviceId = m['service_id']?.toString() ?? '-';

        final qty = m['qty']?.toString() ?? '-';
        final uom = (m['uom'] ?? '').toString();
        final price = (m['computed_price'] ?? m['price'] ?? '-').toString();

        final options = (m['options'] as List?) ?? const [];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (serviceName != null && serviceName.trim().isNotEmpty)
                          ? serviceName
                          : 'Service #$serviceId',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '₱ $price',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $qty ${uom.isEmpty ? '' : uom.toUpperCase()}',
                style: const TextStyle(color: Colors.black54),
              ),

              if (options.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Add-ons',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                ...options.map((o) {
                  final om = o is Map ? Map<String, dynamic>.from(o) : <String, dynamic>{};
                  final so = (om['service_option'] is Map)
                      ? Map<String, dynamic>.from(om['service_option'])
                      : null;

                  final optName = so?['name']?.toString();
                  final optId = om['service_option_id']?.toString() ?? om['id']?.toString() ?? '-';
                  final optPrice = (om['computed_price'] ?? om['price'] ?? '-').toString();
                  final req = om['is_required'];

                  final requiredLabel = (req == true || req == 1 || req == '1') ? ' (required)' : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(optName != null && optName.trim().isNotEmpty) ? optName : 'Option #$optId'}$requiredLabel',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '₱ $optPrice',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              const Divider(height: 18),
            ],
          ),
        );
      }).toList(),

      // ✅ Total summary shown ONCE (not per-item)
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
          Text('₱ $totalLabel', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    ],
  ),
),

        ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Feedback')),
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