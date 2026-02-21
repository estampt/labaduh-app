import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_shops_providers.dart';
import 'vendor_shop_form_screen.dart';
import '../../shop_services/ui/shop_services_screen.dart';

class VendorShopsScreen extends ConsumerWidget {
  const VendorShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorShopsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Shops')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (shops) {
          if (shops.isEmpty) {
            return const Center(child: Text('No shops yet. Tap + to create one.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(vendorShopsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = shops[i];

                final address = _joinAddress(
                  s.addressLine1,
                  s.addressLine2,
                  null, // postalCode if you want
                );

                return Card(
                  clipBehavior: Clip.antiAlias, // ✅ helps the banner clip nicely
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =====================================================
                        // ✅ Header: BANNER ON TOP OF NAME
                        // =====================================================
                        _ShopBanner(
                          name: s.name,
                          url: s.profilePhotoURL,
                          isActive: s.isActive,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),

                            /// ✅ CLICKABLE STATUS PILL
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                try {
                                  await ref.read(vendorShopsActionsProvider).toggle(s.id);

                                  /// Refresh list
                                  ref.invalidate(vendorShopsProvider);
                                } catch (e) {
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update status: $e'),
                                    ),
                                  );
                                }
                              },
                              child: _StatusPill(isActive: s.isActive),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          address.isEmpty ? '—' : address,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =====================================================
                        // Info chips: phone, lat/lng, max orders, max kg
                        // =====================================================
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: _dashIfEmpty(s.phone),
                            ),
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: 'Lat/Lng',
                              value: _formatLatLng(s.latitude, s.longitude),
                            ),
                            _InfoChip(
                              icon: Icons.event_available_outlined,
                              label: 'Max orders/day',
                              value: s.defaultMaxOrdersPerDay?.toString() ?? '—',
                            ),
                            _InfoChip(
                              icon: Icons.scale_outlined,
                              label: 'Max kg/day',
                              value: _formatKg(s.defaultMaxKgPerDay),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // =====================================================
                        // Actions row
                        // =====================================================
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VendorShopFormScreen(editShop: s),
                                ),
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShopServicesScreen(
                                    vendorId: s.vendorId,
                                    shopId: s.id,
                                    shopName: s.name,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.miscellaneous_services),
                              label: const Text('Shop Services'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorShopFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ✅ NEW: Banner widget (replaces CircleAvatar)
class _ShopBanner extends StatelessWidget {
  final String name;
  final String? url;
  final bool isActive;

  const _ShopBanner({
    required this.name,
    required this.url,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 90,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
            image: hasUrl
                ? DecorationImage(
                    image: NetworkImage(url!.trim()),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasUrl
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54,
                    ),
                  ),
                )
              : null,
        ),

        // ✅ Optional: subtle gradient so overlays read well on bright photos
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.22),
                ],
              ),
            ),
          ),
        ),

        // Small active/inactive dot (bottom-right)
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- helpers ----------------

String _dashIfEmpty(String? v) {
  final s = (v ?? '').trim();
  return s.isEmpty ? '—' : s;
}

String _formatLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return '—';
  return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}

String _formatKg(double? kg) {
  if (kg == null) return '—';
  final fixed = kg.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.replaceAll('.0', '') : fixed;
}

String _joinAddress(String? a1, String? a2, String? postal) {
  final parts = <String>[];
  if ((a1 ?? '').trim().isNotEmpty) parts.add(a1!.trim());
  if ((a2 ?? '').trim().isNotEmpty) parts.add(a2!.trim());
  if ((postal ?? '').trim().isNotEmpty) parts.add(postal!.trim());
  return parts.join(', ');
}