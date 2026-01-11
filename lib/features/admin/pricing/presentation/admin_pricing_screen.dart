import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/admin_pricing_controller.dart';
import '../../data/admin_models.dart';

class AdminPricingScreen extends ConsumerWidget {
  const AdminPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(adminPricingProvider);
    final ctrl = ref.read(adminPricingProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('System pricing'),
              subtitle: Text('Vendors can override. This is the default.'),
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((r) => _PricingRowCard(
                row: r,
                onEdit: () => _showEdit(context, r, ctrl),
              )),
        ],
      ),
    );
  }

  Future<void> _showEdit(BuildContext context, PricingRow row, AdminPricingController ctrl) async {
    var baseKg = row.baseKg;
    var basePrice = row.basePrice;
    var excess = row.excessPerKg;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${row.serviceName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Stepper(label: 'Base KG', value: baseKg, onChanged: (v) => baseKg = v),
            _Stepper(label: 'Base Price (₱)', value: basePrice, onChanged: (v) => basePrice = v),
            _Stepper(label: 'Excess / KG (₱)', value: excess, onChanged: (v) => excess = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ctrl.update(row.serviceId, baseKg: baseKg, basePrice: basePrice, excessPerKg: excess);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PricingRowCard extends StatelessWidget {
  const _PricingRowCard({required this.row, required this.onEdit});
  final PricingRow row;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          title: Text(row.serviceName, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('Base: ${row.baseKg} KG • ₱ ${row.basePrice}\nExcess: ₱ ${row.excessPerKg} / KG'),
          isThreeLine: true,
          trailing: IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        ),
      ),
    );
  }
}

class _Stepper extends StatefulWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  late int v;

  @override
  void initState() {
    super.initState();
    v = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(
          onPressed: v > 0
              ? () {
                  setState(() => v -= 1);
                  widget.onChanged(v);
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$v', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(
          onPressed: () {
            setState(() => v += 1);
            widget.onChanged(v);
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
