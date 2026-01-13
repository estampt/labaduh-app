import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../data/token_store.dart';
import '../data/auth_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncData(null));
  final Ref ref;

  /// ✅ LOGIN
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).registerCustomer(
            name: name,
            email: email,
            password: password,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<String?> registerVendor({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required double latitude,
    required double longitude,
    required String businessRegistrationPath,
    required String governmentIdPath,
    List<String> supportingDocPaths = const [],
  }) async {
    state = const AsyncLoading();
    try {
      final vendorId = await ref.read(authRepositoryProvider).registerVendorMultipart(
            name: name,
            email: email,
            password: password,
            businessName: businessName,
            latitude: latitude,
            longitude: longitude,
            businessRegistrationPath: businessRegistrationPath,
            governmentIdPath: governmentIdPath,
            supportingDocPaths: supportingDocPaths,
          );
      state = const AsyncData(null);
      return vendorId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  //Future<void> logout() async {
  //  await ref.read(tokenStoreProvider).clear();
  //}
  Future<void> logout() async {
    try {
      //await _api.dio.post('/api/v1/auth/logout'); // optional
      //TODO: Connect logout API
    } catch (_) {}
    await ref.read(authRepositoryProvider).logout();
  }


}
