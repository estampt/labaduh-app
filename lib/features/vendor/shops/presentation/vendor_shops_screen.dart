import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/vendor_shops_providers.dart';
import 'vendor_shop_form_screen.dart';
import '../pricing/service_options/presentation/vendor_shop_service_prices_screen.dart';

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
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(),
                              ),
                              child: Text(s.isActive ? 'ACTIVE' : 'INACTIVE'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(s.addressLine1 ?? '—'),
                        const SizedBox(height: 12),
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
                              onPressed: () async {
                                await ref.read(vendorShopsActionsProvider).toggle(s.id);
                                ref.invalidate(vendorShopsProvider);
                              },
                              icon: Icon(s.isActive ? Icons.toggle_off : Icons.toggle_on),
                              label: Text(s.isActive ? 'Deactivate' : 'Activate'),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                             onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VendorShopServicePricesScreen(
                                  vendorId: s.vendorId,
                                  shopId: s.id,
                                  shopName: s.name,
                                ),

                                ),
                              ),
                              icon: const Icon(Icons.price_change),
                              label: const Text('Set Pricing'),
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