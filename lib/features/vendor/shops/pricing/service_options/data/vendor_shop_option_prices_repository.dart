import 'package:dio/dio.dart';

<<<<<<< HEAD
=======

>>>>>>> 1349264b72a737564771f56530c6a4ecf36072b7
num? _toNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}
<<<<<<< HEAD

=======
>>>>>>> 1349264b72a737564771f56530c6a4ecf36072b7
class ServiceOptionLite {
  final int id;
  final String name;
  final String? kind; // option | addon
  final String? priceType; // fixed | per_kg | per_item
  final num? price;
  final String? description; // ✅ add this

  ServiceOptionLite({
    required this.id,
    required this.name,
    this.kind,
    this.priceType,
    this.price,
    this.description,
  });

  factory ServiceOptionLite.fromJson(Map<String, dynamic> j) => ServiceOptionLite(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        kind: j['kind']?.toString(),
        priceType: j['price_type']?.toString(),
        price: _toNum(j['price']),
        description: j['description']?.toString(), // ✅ parse this
      );
  
}

class VendorServiceOptionPriceLite {
  final int id;
  final int vendorId;
  final int? shopId;
  final int serviceOptionId;
  final num? price;
  final String? priceType; // fixed | per_kg | per_item
  final bool isActive;

  // Optional: if API returns eager loaded serviceOption
  final ServiceOptionLite? serviceOption;

  VendorServiceOptionPriceLite({
    required this.id,
    required this.vendorId,
    required this.shopId,
    required this.serviceOptionId,
    required this.price,
    required this.priceType,
    required this.isActive,
    this.serviceOption,
  });

  factory VendorServiceOptionPriceLite.fromJson(Map<String, dynamic> j) {
    final so = j['service_option'];
    return VendorServiceOptionPriceLite(
      id: (j['id'] as num).toInt(),
      vendorId: (j['vendor_id'] as num).toInt(),
      shopId: j['shop_id'] == null ? null : (j['shop_id'] as num).toInt(),
      serviceOptionId: (j['service_option_id'] as num).toInt(),
      price: _toNum(j['price']),
      priceType: j['price_type']?.toString(),
      isActive: (j['is_active'] == true),
      serviceOption: (so is Map<String, dynamic>) ? ServiceOptionLite.fromJson(so) : null,
    );
  }
}

class VendorShopOptionPricesRepository {
  VendorShopOptionPricesRepository(this._dio);

  final Dio _dio;

  /// GET /vendors/{vendor}/shops/{shop}/option-prices?vendor_service_price_id=...
  Future<List<VendorServiceOptionPriceLite>> listShopOptionPrices({
    required int vendorId,
    required int shopId,
    required int vendorServicePriceId, // ✅ REQUIRED
    int? serviceOptionId,              // ✅ optional filter
  }) async {
    final res = await _dio.get(
      '/api/v1/vendors/$vendorId/shops/$shopId/option-prices',
      queryParameters: {
        'vendor_service_price_id': vendorServicePriceId,
        if (serviceOptionId != null) 'service_option_id': serviceOptionId,
      },
    );

    final data = res.data;
    final List list = (data['data']?['data'] as List?) ?? const [];

    return list
        .map((e) => VendorServiceOptionPriceLite.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }


  /// POST /vendors/{vendor}/shops/{shop}/option-prices  (upsert)
  Future<VendorServiceOptionPriceLite> upsertShopOptionPrice({
    required int vendorId,
    required int shopId,
    required int serviceOptionId,
    required int vendorServicePriceId,
    num? price,
    String? priceType, // fixed|per_kg|per_item
    bool? isActive,
  }) async {
    final res = await _dio.post(
      '/api/v1/vendors/$vendorId/shops/$shopId/option-prices',
      data: {
        'service_option_id': serviceOptionId,
        if (price != null) 'price': price,
        if (priceType != null) 'price_type': priceType,
        if (isActive != null) 'is_active': isActive,
      },
    );

    final j = Map<String, dynamic>.from(res.data['data'] ?? res.data);
    return VendorServiceOptionPriceLite.fromJson(j);
  }

  /// PUT /vendors/{vendor}/shops/{shop}/option-prices/{id}
  Future<VendorServiceOptionPriceLite> updateShopOptionPrice({
    required int vendorId,
    required int shopId,
    required int optionPriceId,
    num? price,
    String? priceType,
    bool? isActive,
  }) async {
    final res = await _dio.put(
      '/api/v1/vendors/$vendorId/shops/$shopId/option-prices/$optionPriceId',
      data: {
        if (price != null) 'price': price,
        if (priceType != null) 'price_type': priceType,
        if (isActive != null) 'is_active': isActive,
      },
    );

    final j = Map<String, dynamic>.from(res.data['data'] ?? res.data);
    return VendorServiceOptionPriceLite.fromJson(j);
  }

  /// DELETE /vendors/{vendor}/shops/{shop}/option-prices/{id}
  Future<void> deleteShopOptionPrice({
    required int vendorId,
    required int shopId,
    required int optionPriceId,
  }) async {
    await _dio.delete('/api/v1/vendors/$vendorId/shops/$shopId/option-prices/$optionPriceId');
  }

  /// GET /service-options (master list for picker)
  /// If your backend returns paginator, adjust parsing below.
  Future<List<ServiceOptionLite>> listServiceOptions({bool onlyActive = true}) async {
    final res = await _dio.get('/api/v1/service-options', queryParameters: {
      if (onlyActive) 'active': 1,
      // if you later want filter: kind=addon|option
      // 'kind': 'addon',
    });

    final data = res.data;
    // common patterns:
    // 1) {data: [...]}
    // 2) {data: {data:[...]}}
    final List list =
        (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : ((data['data']?['data'] as List?) ?? const []);

    return list.map((e) => ServiceOptionLite.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
