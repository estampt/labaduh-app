import 'dart:io';

import 'package:dio/dio.dart';

import '../domain/vendor_shop.dart';

class VendorShopsRepository {
  VendorShopsRepository(this.api);
  final dynamic api; // ApiClient

  // ✅ CHANGE THIS ONE LINE if your ApiClient uses a different field name
  dynamic get _dio => api.dio; // <-- if yours is api.client or api.http, change here

  Future<List<VendorShop>> list({required int vendorId}) async {
    final res = await _dio.get('/api/v1/vendors/$vendorId/shops');
    final body = res.data;

    // ✅ paginated: { data: { data: [...] } }
    final items = (body['data']['data'] as List).cast<Map<String, dynamic>>();
    return items.map(VendorShop.fromJson).toList();
  }

  Future<VendorShop> create({
    required int vendorId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.post('/api/v1/vendors/$vendorId/shops', data: payload);
    final body = res.data;

    final shopJson = (body['data'] ?? body) as Map<String, dynamic>;
    return VendorShop.fromJson(shopJson);
  }

  Future<VendorShop> update({
    required int vendorId,
    required int shopId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _dio.put('/api/v1/vendors/$vendorId/shops/$shopId', data: payload);
    final body = res.data;

    final shopJson = (body['data'] ?? body) as Map<String, dynamic>;
    return VendorShop.fromJson(shopJson);
  }

  Future<void> toggle({required int vendorId, required int shopId}) async {
    await _dio.patch('/api/v1/vendors/$vendorId/shops/$shopId/toggle');
  }

  /// ✅ Single photo per shop
  /// POST /api/v1/vendors/{vendor}/shops/{shop}/photo  (multipart)
  Future<VendorShop> uploadPhoto({
    required int vendorId,
    required int shopId,
    required File photoFile,
  }) async {
    final fileName = photoFile.path.split(Platform.pathSeparator).last;

    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoFile.path, filename: fileName),
    });

    final res = await _dio.post(
      '/api/v1/vendors/$vendorId/shops/$shopId/photo',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = res.data;
    final shopJson = (body['data'] ?? body) as Map<String, dynamic>;
    return VendorShop.fromJson(shopJson);
  }
}
