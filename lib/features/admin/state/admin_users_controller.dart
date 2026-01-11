import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_models.dart';
import '../data/admin_seed.dart';

final adminUsersProvider = StateNotifierProvider<AdminUsersController, List<AdminUser>>((ref) {
  return AdminUsersController()..seed();
});

class AdminUsersController extends StateNotifier<List<AdminUser>> {
  AdminUsersController() : super(const []);

  void seed() => state = [...seedUsers];
}
