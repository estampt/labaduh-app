import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vendor_pricing.dart';
import '../state/vendor_pricing_controller.dart';

class VendorPricingScreen extends ConsumerWidget {
  const VendorPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = ref.watch(vendorPricingProvider);
    final ctrl = ref.read(vendorPricingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: pricing.useSystemPricing,
                onChanged: ctrl.setUseSystemPricing,
                title: const Text('Use system pricing', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Turn off to set your own rates'),
              ),
            ),
            const SizedBox(height: 12),
            ...pricing.services.map((s) => _ServicePriceCard(
                  service: s,
                  enabled: !pricing.useSystemPricing,
                  onChange: (baseKg, basePrice, excess) =>
                      ctrl.updateService(s.serviceId, baseKg: baseKg, basePrice: basePrice, excessPerKg: excess),
                )),
          ],
        ),
      ),
    );
  }
}

class _ServicePriceCard extends StatelessWidget {
  const _ServicePriceCard({required this.service, required this.enabled, required this.onChange});
  final VendorServicePrice service;
  final bool enabled;
  final void Function(int baseKg, int basePrice, int excessPerKg) onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.serviceName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _RowEditor(label: 'Base KG', value: service.baseKg, enabled: enabled, onChanged: (v) => onChange(v, service.basePrice, service.excessPerKg)),
              const SizedBox(height: 10),
              _RowEditor(label: 'Base price (₱)', value: service.basePrice, enabled: enabled, onChanged: (v) => onChange(service.baseKg, v, service.excessPerKg)),
              const SizedBox(height: 10),
              _RowEditor(label: 'Excess per KG (₱)', value: service.excessPerKg, enabled: enabled, onChanged: (v) => onChange(service.baseKg, service.basePrice, v)),
              if (!enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('System pricing enabled', style: TextStyle(color: Colors.black54)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({required this.label, required this.value, required this.enabled, required this.onChanged});
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(onPressed: enabled ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}
