import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});

class SettingsState {
  const SettingsState({this.pushNotifications = true, this.smsUpdates = false, this.marketing = false});

  final bool pushNotifications;
  final bool smsUpdates;
  final bool marketing;

  SettingsState copyWith({bool? pushNotifications, bool? smsUpdates, bool? marketing}) {
    return SettingsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsUpdates: smsUpdates ?? this.smsUpdates,
      marketing: marketing ?? this.marketing,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState());

  void setPush(bool v) => state = state.copyWith(pushNotifications: v);
  void setSms(bool v) => state = state.copyWith(smsUpdates: v);
  void setMarketing(bool v) => state = state.copyWith(marketing: v);
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    value: s.pushNotifications,
                    onChanged: c.setPush,
                    title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Order status updates'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: s.smsUpdates,
                    onChanged: c.setSms,
                    title: const Text('SMS updates', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Backup notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: s.marketing,
                onChanged: c.setMarketing,
                title: const Text('Marketing messages', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Promos and announcements'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
