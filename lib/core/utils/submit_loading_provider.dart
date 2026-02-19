import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic loading lock you can reuse anywhere.
///
/// Usage:
///   final isLoading = ref.watch(submitLoadingProvider('vendor_order_submit'));
///   await ref.read(submitLoadingProvider('vendor_order_submit').notifier)
///       .run(() async { ... });
final submitLoadingProvider =
    StateNotifierProvider.family<SubmitLoadingController, bool, String>(
  (ref, key) => SubmitLoadingController(),
);

class SubmitLoadingController extends StateNotifier<bool> {
  SubmitLoadingController() : super(false);

  /// Run an async task with auto-loading state + anti-double-tap protection.
  ///
  /// Returns:
  /// - null if it was already running (blocked)
  /// - otherwise returns the task result
  Future<T?> run<T>(Future<T> Function() task) async {
    if (state) return null; // already running
    state = true;
    try {
      return await task();
    } finally {
      state = false;
    }
  }

  void set(bool value) => state = value;
}
