import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/app_bootstrap.dart';
import 'app/theme/app_theme.dart';
import 'di/providers.dart';
import 'l10n/app_localizations.dart';
import 'features/profile/providers/settings_providers.dart';

Future<void> main() async {
  await bootstrapApp();
  runApp(const ProviderScope(child: MraApp()));
}

class MraApp extends ConsumerWidget {
  const MraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    final darkMode = ref.watch(darkModeProvider);
    final largeTextMode = ref.watch(largeTextModeProvider);
    
    final themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: 'Medical Reminder App',
      theme: AppTheme.light().copyWith(
        textTheme: AppTheme.light().textTheme.apply(
          bodyColor: AppTheme.light().textTheme.bodyLarge?.color,
          fontSizeFactor: largeTextMode ? 1.3 : 1.0,
        ),
      ),
      darkTheme: AppTheme.dark().copyWith(
        textTheme: AppTheme.dark().textTheme.apply(
          bodyColor: AppTheme.dark().textTheme.bodyLarge?.color,
          fontSizeFactor: largeTextMode ? 1.3 : 1.0,
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(largeTextMode ? 1.3 : 1.0),
          ),
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('sw', ''),
      ],
    );
  }
}
