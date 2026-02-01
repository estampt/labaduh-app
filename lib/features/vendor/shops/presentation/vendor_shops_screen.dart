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
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                try {
                                  await ref.read(vendorShopsActionsProvider).toggle(s.id);
                                  ref.invalidate(vendorShopsProvider);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update status: $e')),
                                  );
                                }
                              },
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: s.isActive
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),

                                  // ✅ SOLID border (inner border only)
                                  border: Border.all(
                                    width: 1,
                                    color: s.isActive ? Colors.green : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      s.isActive
                                          ? Icons.check_circle_outline
                                          : Icons.pause_circle_outline,
                                      size: 16,
                                      color: s.isActive ? Colors.green : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: s.isActive ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),


                            const Spacer(),
                            OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopServicesScreen(
                                  vendorId: s.vendorId,
                                  shopId: s.id,
                                  shopName: s.name, // ✅ add this
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