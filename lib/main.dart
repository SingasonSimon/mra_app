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

    final baseLightTheme = AppTheme.light();
    final baseDarkTheme = AppTheme.dark();

    // Apply large text mode using textScaler instead of fontSizeFactor
    // This avoids the fontSize assertion error
    final lightTheme = baseLightTheme;
    final darkTheme = baseDarkTheme;

    return MaterialApp.router(
      title: 'Medical Reminder App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(largeTextMode ? 1.3 : 1.0),
            ),
            child: ScaffoldMessenger(
              child: child!,
            ),
          ),
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
