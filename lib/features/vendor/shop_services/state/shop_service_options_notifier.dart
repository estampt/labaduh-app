import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/shop_service_options_dtos.dart';
import '../data/shop_service_options_repository.dart';
import '../data/master_service_options_repository.dart';

final shopServiceOptionsRepositoryProvider =
    Provider<ShopServiceOptionsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ShopServiceOptionsRepository(api);
});

final masterServiceOptionsRepositoryProvider =
    Provider<MasterServiceOptionsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MasterServiceOptionsRepository(api);
});

// master options list (cached)
final masterServiceOptionsProvider =
    FutureProvider<List<ServiceOptionDto>>((ref) async {
  final repo = ref.read(masterServiceOptionsRepositoryProvider);
  return repo.listAll();
});

final shopServiceOptionsProvider = StateNotifierProvider.autoDispose<
    ShopServiceOptionsNotifier,
    AsyncValue<List<ShopServiceOptionDto>>>((ref) {
  final repo = ref.read(shopServiceOptionsRepositoryProvider);
  return ShopServiceOptionsNotifier(repo);
});

class ShopServiceOptionsNotifier
    extends StateNotifier<AsyncValue<List<ShopServiceOptionDto>>> {
  ShopServiceOptionsNotifier(this._repo)
      : super(const AsyncValue.loading());

  final ShopServiceOptionsRepository _repo;

  int? _vendorId;
  int? _shopId;
  int? _shopServiceId;

  Future<void> load({
    required int vendorId,
    required int shopId,
    required int shopServiceId,
  }) async {
    _vendorId = vendorId;
    _shopId = shopId;
    _shopServiceId = shopServiceId;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final rows = await _repo.list(vendorId, shopId, shopServiceId);
      rows.sort(_sort);
      return rows;
    });
  }

  Future<void> refresh() async {
    final v = _vendorId;
    final s = _shopId;
    final ss = _shopServiceId;
    if (v == null || s == null || ss == null) return;
    await load(vendorId: v, shopId: s, shopServiceId: ss);
  }

  Future<ShopServiceOptionDto> create(Map<String, dynamic> payload) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;

    try {
      final created = await _repo.create(v, s, ss, payload);

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, created]..sort(_sort));
      return created;
    } catch (e, st) {
      final msg = _friendlyApiMessage(e);
      Error.throwWithStackTrace(Exception(msg), st);
    }
  }

  Future<ShopServiceOptionDto> update(int id, Map<String, dynamic> payload) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;

    try {
      final updated = await _repo.update(v, s, ss, id, payload);

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.map((e) => e.id == id ? updated : e).toList()..sort(_sort),
      );
      return updated;
    } catch (e, st) {
      final msg = _friendlyApiMessage(e);
      Error.throwWithStackTrace(Exception(msg), st);
    }
  }

  Future<void> delete(int id) async {
    final v = _vendorId!;
    final s = _shopId!;
    final ss = _shopServiceId!;

    try {
      await _repo.delete(v, s, ss, id);

      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(
        current.where((e) => e.id != id).toList()..sort(_sort),
      );
    } catch (e, st) {
      final msg = _friendlyApiMessage(e);
      Error.throwWithStackTrace(Exception(msg), st);
    }
  }

  /// ✅ Converts Dio/Laravel validation errors into a clean message for UI.
  ///
  /// Expected backend shape:
  /// {
  ///   "message": "This add-on/option already exists for this service.",
  ///   "errors": { "service_option_id": ["Duplicate service_option_id for this shop service."] }
  /// }
  String _friendlyApiMessage(Object err) {
    // Dio exceptions (most common with ApiClient)
    if (err is DioException) {
      final data = err.response?.data;

      if (data is Map) {
        final message = (data['message'] ?? '').toString().trim();

        // Grab the first validation error (if any)
        String firstError = '';
        final errors = data['errors'];
        if (errors is Map) {
          for (final entry in errors.entries) {
            final v = entry.value;
            if (v is List && v.isNotEmpty) {
              firstError = v.first.toString().trim();
              break;
            }
            if (v is String && v.trim().isNotEmpty) {
              firstError = v.trim();
              break;
            }
          }
        }

        if (message.isNotEmpty && firstError.isNotEmpty) {
          return '$message ($firstError)';
        }
        if (message.isNotEmpty) return message;
        if (firstError.isNotEmpty) return firstError;
      }

      // Fallbacks
      final status = err.response?.statusCode;
      final dioMsg = err.message?.trim();
      if (dioMsg != null && dioMsg.isNotEmpty) {
        return status != null ? 'Request failed ($status): $dioMsg' : dioMsg;
      }
      return status != null ? 'Request failed ($status).' : 'Request failed.';
    }

    // Generic fallback
    final s = err.toString();
    return s.isNotEmpty ? s : 'Something went wrong.';
  }

  int _sort(ShopServiceOptionDto a, ShopServiceOptionDto b) {
    final so = a.sortOrder.compareTo(b.sortOrder);
    if (so != 0) return so;
    final an = (a.serviceOption?.name ?? '').toLowerCase();
    final bn = (b.serviceOption?.name ?? '').toLowerCase();
    return an.compareTo(bn);
  }
}