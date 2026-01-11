import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vendorSettingsProvider =
    StateNotifierProvider<VendorSettingsController, VendorSettingsState>((ref) {
  return VendorSettingsController();
});

class VendorSettingsState {
  const VendorSettingsState({this.autoAccept = false, this.pushNotifications = true, this.soundAlerts = true});

  final bool autoAccept;
  final bool pushNotifications;
  final bool soundAlerts;

  VendorSettingsState copyWith({bool? autoAccept, bool? pushNotifications, bool? soundAlerts}) {
    return VendorSettingsState(
      autoAccept: autoAccept ?? this.autoAccept,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      soundAlerts: soundAlerts ?? this.soundAlerts,
    );
  }
}

class VendorSettingsController extends StateNotifier<VendorSettingsState> {
  VendorSettingsController() : super(const VendorSettingsState());

  void setAutoAccept(bool v) => state = state.copyWith(autoAccept: v);
  void setPush(bool v) => state = state.copyWith(pushNotifications: v);
  void setSound(bool v) => state = state.copyWith(soundAlerts: v);
}

class VendorSettingsScreen extends ConsumerWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(vendorSettingsProvider);
    final c = ref.read(vendorSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: s.autoAccept,
                    onChanged: c.setAutoAccept,
                    title: const Text('Auto-accept orders', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('Automatically accept when you are available'),
                    secondary: const Icon(Icons.flash_on_outlined),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: s.pushNotifications,
                    onChanged: c.setPush,
                    title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w900)),
                    secondary: const Icon(Icons.notifications_outlined),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: s.soundAlerts,
                    onChanged: c.setSound,
                    title: const Text('Sound alerts', style: TextStyle(fontWeight: FontWeight.w900)),
                    secondary: const Icon(Icons.volume_up_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
