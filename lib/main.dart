import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app_bootstrap.dart';
import 'app/theme/app_theme.dart';
import 'di/providers.dart';

Future<void> main() async {
  await bootstrapApp();
  runApp(const ProviderScope(child: MraApp()));
}

class MraApp extends ConsumerWidget {
  const MraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Medical Reminder App',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
