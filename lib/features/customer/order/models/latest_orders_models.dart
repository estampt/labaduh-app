class LatestOrdersResponse {
  final List<LatestOrder> data;
  final String? cursor;

  LatestOrdersResponse({required this.data, required this.cursor});

  factory LatestOrdersResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List? ?? [])
        .map((e) => LatestOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return LatestOrdersResponse(
      data: list,
      cursor: j['cursor']?.toString(),
    );
  }
}

class LatestOrder {
  final int id;
  final String status;
  final String pricingStatus;
  final num estimatedTotal;
  final num? finalTotal;
  final DateTime createdAt;

  final dynamic shop;   // keep dynamic for now (null in sample)
  final dynamic driver; // keep dynamic for now (null in sample)

  final List<LatestOrderItem> items;

  LatestOrder({
    required this.id,
    required this.status,
    required this.pricingStatus,
    required this.estimatedTotal,
    required this.finalTotal,
    required this.createdAt,
    required this.shop,
    required this.driver,
    required this.items,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory LatestOrder.fromJson(Map<String, dynamic> j) {
    return LatestOrder(
      id: j['id'] as int,
      status: (j['status'] ?? '').toString(),
      pricingStatus: (j['pricing_status'] ?? '').toString(),
      estimatedTotal: _toNum(j['estimated_total']),
      finalTotal: j['final_total'] == null ? null : _toNum(j['final_total']),
      createdAt: DateTime.parse((j['created_at'] ?? '').toString()),
      shop: j['shop'],
      driver: j['driver'],
      items: (j['items'] as List? ?? [])
          .map((e) => LatestOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  num get displayTotal => finalTotal ?? estimatedTotal;
}

class LatestOrderItem {
  final int id;
  final int serviceId;
  final num qty;
  final num price;
  final List<LatestOrderItemOption> options;

  LatestOrderItem({
    required this.id,
    required this.serviceId,
    required this.qty,
    required this.price,
    required this.options,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory LatestOrderItem.fromJson(Map<String, dynamic> j) {
    return LatestOrderItem(
      id: j['id'] as int,
      serviceId: j['service_id'] as int,
      qty: _toNum(j['qty']),
      price: _toNum(j['price']),
      options: (j['options'] as List? ?? [])
          .map((e) => LatestOrderItemOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LatestOrderItemOption {
  final int id;
  final String? name;
  final num price;

  LatestOrderItemOption({
    required this.id,
    required this.name,
    required this.price,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory LatestOrderItemOption.fromJson(Map<String, dynamic> j) {
    return LatestOrderItemOption(
      id: j['id'] as int,
      name: j['name']?.toString(),
      price: _toNum(j['price']),
    );
  }
}
