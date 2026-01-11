import 'package:flutter/material.dart';

class KgStepper extends StatelessWidget {
  const KgStepper({
    super.key,
    required this.value,
    required this.min,
    required this.onChanged,
    required this.suffix,
  });

  final int value;
  final int min;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value $suffix', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
