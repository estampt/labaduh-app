import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/discovery_service_models.dart';
import '../models/order_models.dart';
import '../models/order_payloads.dart';
import '../models/latest_orders_models.dart';
import 'package:image_picker/image_picker.dart';

class CustomerOrdersApi {
  final Dio dio;
  CustomerOrdersApi(this.dio);

  Future<LatestOrdersResponse> latestOrders({String? cursor}) async {
    final res = await dio.get(
      '/api/v1/customer/orders/latest',
      queryParameters: cursor == null ? null : {'cursor': cursor},
    );

    return LatestOrdersResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<List<DiscoveryServiceRow>> discoveryServices({
    required double lat,
    required double lng,
    required int radiusKm,
  }) async {
    final res = await dio.get(
      '/api/v1/customer/discovery/services',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
      },
    );

    final data = (res.data as Map?)?['data'] as List?;
    return (data ?? [])
        .map((e) => DiscoveryServiceRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Order> createOrder(CreateOrderPayload payload) async {
    final res = await dio.post('/api/v1/customer/orders', data: payload.toJson());
    final data = (res.data as Map?)?['data'];
    if (data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Invalid response: missing data',
      );
    }
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Order> confirmDelivery(int orderId) async {
    final res = await dio.post('/api/v1/customer/orders/$orderId/confirm-delivery');
    final data = (res.data as Map?)?['data'];
    if (data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Invalid response: missing data',
      );
    }
    return Order.fromJson(Map<String, dynamic>.from(data));
  }



  /// Submit feedback for an order.
  /// Request body:
  /// {
  ///   "rating": 5,
  ///   "comments": "Maau molaba.",
  ///   "image_urls": ["https://.../1.jpg", "https://.../2.jpg"]
  /// }
  ///
  /// Returns the raw JSON response (usually {"data": {...}}).
  Future<Map<String, dynamic>> submitFeedback(
    int orderId, {
    required int rating,
    String? comments,
    List<String>? imageUrls,
  }) async {
    final trimmed = comments?.trim();
    final urls = (imageUrls ?? [])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'rating': rating,
      'comments': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      'image_urls': urls.isEmpty ? null : urls,
    };

    final res = await dio.post(
      '/api/v1/customer/orders/$orderId/feedback',
      data: payload,
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Submit feedback with optional multiple images
  
  
Future<void> submitFeedbackMultipart({
  required int orderId,
  required int rating,
  String? comments,
  List<XFile> images = const [],
  ProgressCallback? onSendProgress,
}) async {
  final formData = FormData();

  formData.fields.add(MapEntry('rating', rating.toString()));

  final c = comments?.trim();
  if (c != null && c.isNotEmpty) {
    formData.fields.add(MapEntry('comments', c));
  }

  for (final img in images) {
    if (kIsWeb) {
      // ✅ Web: no dart:io, use bytes
      final bytes = await img.readAsBytes();
      formData.files.add(
        MapEntry(
          'images[]',
          MultipartFile.fromBytes(
            bytes,
            filename: img.name.isNotEmpty ? img.name : 'upload.jpg',
          ),
        ),
      );
    } else {
      // ✅ Mobile/Desktop: use file path
      formData.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            img.path,
            filename: img.name,
          ),
        ),
      );
    }
  }

  await dio.post(
    '/api/v1/customer/orders/$orderId/feedback',
    data: formData,
    // Optional; Dio will set boundary automatically
    // options: Options(contentType: 'multipart/form-data'),
    onSendProgress: onSendProgress,
  );

  }
}
