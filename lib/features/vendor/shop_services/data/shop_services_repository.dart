 
import 'shop_services_dtos.dart';

import '../../../../core/network/api_client.dart';  


class ShopServicesRepository {
  ShopServicesRepository(this._api);
  final ApiClient _api;

  String _base(int vendorId, int shopId) =>
      '/api/v1/vendors/$vendorId/shops/$shopId/services';

  Future<List<ShopServiceDto>> list(int vendorId, int shopId) async {
    final res = await _api.dio.get(_base(vendorId, shopId));
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(ShopServiceDto.fromJson).toList();
  }

  Future<ShopServiceDto> create(int vendorId, int shopId, Map<String, dynamic> payload) async {
    final res = await _api.dio.post(_base(vendorId, shopId), data: payload);
    return ShopServiceDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ShopServiceDto> update(int vendorId, int shopId, int id, Map<String, dynamic> payload) async {
    final res = await _api.dio.put('${_base(vendorId, shopId)}/$id', data: payload);
    return ShopServiceDto.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int vendorId, int shopId, int id) async {
    await _api.dio.delete('${_base(vendorId, shopId)}/$id');
  }
}
