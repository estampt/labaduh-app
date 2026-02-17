import 'package:flutter/material.dart';
import '../domain/order_status.dart';
import '../utils/order_status_utils.dart';

class OrderStatusDropdown extends StatelessWidget {
  final OrderStatus? value;
  final ValueChanged<OrderStatus?> onChanged;
  final bool includeAll;

  const OrderStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    // Build list
    final statuses = <OrderStatus>[
      if (includeAll) OrderStatus.unknown, // used as "All"
      ...OrderStatus.values.where(
        (s) => s != OrderStatus.unknown,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderStatus?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),

          items: statuses.map((status) {
            final isAll = status == OrderStatus.unknown;

            return DropdownMenuItem<OrderStatus?>(
              value: status,
              child: Row(
                children: [
                  if (!isAll)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: OrderStatusUtils.color(status),
                        shape: BoxShape.circle,
                      ),
                    ),

                  Text(
                    isAll
                        ? 'All Orders'
                        : OrderStatusUtils.label(status),
                  ),
                ],
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }
}
