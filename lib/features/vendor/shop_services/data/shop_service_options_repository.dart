import '../../../../core/network/api_client.dart';
import 'shop_service_options_dtos.dart';

class ShopServiceOptionsRepository {
  ShopServiceOptionsRepository(this._api);
  final ApiClient _api;

  // ✅ existing (options for ONE shopService)
  String _optionsBase(int vendorId, int shopId, int shopServiceId) =>
      '/api/v1/vendors/$vendorId/shops/$shopId/services/$shopServiceId/options';

  // ✅ NEW (shop services list with nested service + options)
  String _servicesBase(int vendorId, int shopId) =>
      '/api/v1/vendors/$vendorId/shops/$shopId/services';

  /// ✅ NEW: get JSON like your sample:
  /// { "data": [ { id, shop_id, service_id, ..., service:{}, options:[{...,pivot:{}}] } ] }
  ///
  /// IMPORTANT:
  /// - This assumes your existing DTO can parse that shape.
  /// - If your existing DTO class name is NOT ShopServiceOptionDto for this response,
  ///   replace ShopServiceOptionDto below with the correct existing DTO you already have.
  Future<List<ShopServiceOptionDto>> listShopServices(
    int vendorId,
    int shopId,
  ) async {
    final res = await _api.dio.get(_servicesBase(vendorId, shopId));

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected response: root is not an object');
    }

    final raw = data['data'];
    if (raw is! List) {
      throw Exception('Unexpected response: data is not a list');
    }

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(ShopServiceOptionDto.fromJson) // ✅ uses your EXISTING DTO
        .toList();
  }

  /// ✅ existing: list options for ONE shop service
  Future<List<ShopServiceOptionDto>> list(
      int vendorId, int shopId, int shopServiceId) async {
    final res = await _api.dio.get(_optionsBase(vendorId, shopId, shopServiceId));
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(ShopServiceOptionDto.fromJson).toList();
  }

  Future<ShopServiceOptionDto> create(
      int vendorId, int shopId, int shopServiceId, Map<String, dynamic> payload) async {
    final res = await _api.dio.post(
      _optionsBase(vendorId, shopId, shopServiceId),
      data: payload,
    );
    return ShopServiceOptionDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ShopServiceOptionDto> update(
      int vendorId, int shopId, int shopServiceId, int id, Map<String, dynamic> payload) async {
    final res = await _api.dio.put(
      '${_optionsBase(vendorId, shopId, shopServiceId)}/$id',
      data: payload,
    );
    return ShopServiceOptionDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int vendorId, int shopId, int shopServiceId, int id) async {
    await _api.dio.delete('${_optionsBase(vendorId, shopId, shopServiceId)}/$id');
  }
}