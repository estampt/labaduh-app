class Order {
  final int id;
  final String status;

  final num subtotal;
  final num deliveryFee;
  final num serviceFee;
  final num discount;
  final num total;

  Order({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        status: (j['status'] ?? '').toString(),
        subtotal: _toNum(j['subtotal']),
        deliveryFee: _toNum(j['delivery_fee']),
        serviceFee: _toNum(j['service_fee']),
        discount: _toNum(j['discount']),
        total: _toNum(j['total']),
      );
}
