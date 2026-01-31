import '../../../../core/network/api_client.dart';
import 'shop_service_options_dtos.dart';

class ShopServiceOptionsRepository {
  ShopServiceOptionsRepository(this._api);
  final ApiClient _api;

  String _base(int vendorId, int shopId, int shopServiceId) =>
      '/api/v1/vendors/$vendorId/shops/$shopId/services/$shopServiceId/options';

  Future<List<ShopServiceOptionDto>> list(
      int vendorId, int shopId, int shopServiceId) async {
    final res = await _api.dio.get(_base(vendorId, shopId, shopServiceId));
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(ShopServiceOptionDto.fromJson).toList();
  }

  Future<ShopServiceOptionDto> create(
      int vendorId, int shopId, int shopServiceId, Map<String, dynamic> payload) async {
    final res = await _api.dio.post(
      _base(vendorId, shopId, shopServiceId),
      data: payload,
    );
    return ShopServiceOptionDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ShopServiceOptionDto> update(
      int vendorId, int shopId, int shopServiceId, int id, Map<String, dynamic> payload) async {
    final res = await _api.dio.put(
      '${_base(vendorId, shopId, shopServiceId)}/$id',
      data: payload,
    );
    return ShopServiceOptionDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int vendorId, int shopId, int shopServiceId, int id) async {
    await _api.dio.delete('${_base(vendorId, shopId, shopServiceId)}/$id');
  }
}
