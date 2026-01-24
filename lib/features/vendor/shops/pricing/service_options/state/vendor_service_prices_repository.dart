import 'package:dio/dio.dart';

class VendorServicePricesRepository {
  VendorServicePricesRepository(this.api);
  final dynamic api; // ApiClient

  dynamic get _dio => api.dio;

  // ✅ Adjust these endpoints to match your final Laravel routes
  // Suggested:
  // GET    /api/v1/vendors/{vendor}/shops/{shop}/service-prices
  // POST   /api/v1/vendors/{vendor}/shops/{shop}/service-prices
  // PUT    /api/v1/vendors/{vendor}/shops/{shop}/service-prices/{id}
  // DELETE /api/v1/vendors/{vendor}/shops/{shop}/service-prices/{id}

  Future<List<Map<String, dynamic>>> list({
    required int vendorId,
    required int shopId,
  }) async {
    final res = await _dio.get('/api/v1/vendors/$vendorId/shops/$shopId/service-prices');
    final body = res.data;

    // support either: {data: [...] } OR paginated {data:{data:[...]}}
    final data = body['data'];
    final items = data is List ? data : (data['data'] as List);

    return items.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required int vendorId,
    required int shopId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post(
      '/api/v1/vendors/$vendorId/shops/$shopId/service-prices',
      data: payload,
    );
    final body = res.data;
    return (body['data'] ?? body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update({
    required int vendorId,
    required int shopId,
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.put(
      '/api/v1/vendors/$vendorId/shops/$shopId/service-prices/$id',
      data: payload,
    );
    final body = res.data;
    return (body['data'] ?? body) as Map<String, dynamic>;
  }

  Future<void> delete({
    required int vendorId,
    required int shopId,
    required int id,
  }) async {
    await _dio.delete('/api/v1/vendors/$vendorId/shops/$shopId/service-prices/$id');
  }
}
