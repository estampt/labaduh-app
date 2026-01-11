import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/address.dart';

final addressesProvider = StateNotifierProvider<AddressesController, List<Address>>((ref) {
  return AddressesController()..seed();
});

class AddressesController extends StateNotifier<List<Address>> {
  AddressesController() : super(const []);

  void seed() {
    state = [
      Address(
        id: 'a1',
        label: 'Home',
        line1: '123 Sample Street',
        line2: 'Unit 4B',
        city: 'Quezon City',
        notes: 'Call upon arrival',
      ),
    ];
  }

  void upsert(Address address) {
    final idx = state.indexWhere((a) => a.id == address.id);
    if (idx == -1) {
      state = [...state, address];
    } else {
      final copy = [...state];
      copy[idx] = address;
      state = copy;
    }
  }

  void remove(String id) => state = state.where((a) => a.id != id).toList();
}
