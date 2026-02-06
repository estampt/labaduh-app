num _n(dynamic v) => v == null ? 0 : num.parse(v.toString());
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

class TimelineStepDto {
  final String key;
  final String label;
  final String state; // done/current/todo
  final DateTime? at;

  TimelineStepDto({
    required this.key,
    required this.label,
    required this.state,
    required this.at,
  });

  factory TimelineStepDto.fromJson(Map<String, dynamic> j) => TimelineStepDto(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
        at: _dt(j['at']),
      );
}

class TimelineDto {
  final String current;
  final List<TimelineStepDto> steps;
  final bool requiresCustomerAction;
  final String deliveryMode;

  TimelineDto({
    required this.current,
    required this.steps,
    required this.requiresCustomerAction,
    required this.deliveryMode,
  });

  factory TimelineDto.fromJson(Map<String, dynamic> j) => TimelineDto(
        current: (j['current'] ?? '').toString(),
        steps: ((j['steps'] as List?) ?? [])
            .map((e) => TimelineStepDto.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        requiresCustomerAction: j['flags']?['requires_customer_action'] == true,
        deliveryMode: (j['flags']?['delivery_mode'] ?? '').toString(),
      );
}

class OrderDto {
  final int id;
  final String status;
  final String currency;
  final num total;

  OrderDto({
    required this.id,
    required this.status,
    required this.currency,
    required this.total,
  });

  factory OrderDto.fromJson(Map<String, dynamic> j) => OrderDto(
        id: (j['id'] ?? 0) as int,
        status: (j['status'] ?? '').toString(),
        currency: (j['currency'] ?? '').toString(),
        total: _n(j['total']),
      );
}

class CustomerOrderShowDto {
  final OrderDto order;
  final TimelineDto timeline;

  CustomerOrderShowDto({required this.order, required this.timeline});

  factory CustomerOrderShowDto.fromJson(Map<String, dynamic> j) => CustomerOrderShowDto(
        order: OrderDto.fromJson((j['order'] as Map).cast<String, dynamic>()),
        timeline: TimelineDto.fromJson((j['timeline'] as Map).cast<String, dynamic>()),
      );
}
