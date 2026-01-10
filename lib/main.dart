import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment here (dev/prod). You can later wire this to flavors.
  Env.init(EnvMode.dev);

  runApp(const ProviderScope(child: LabaduhApp()));
}
