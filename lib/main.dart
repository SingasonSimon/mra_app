import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Set system UI overlay style globally - use teal color for status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppTheme.teal500,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: AppTheme.teal500, // Teal background for status bar (time, battery, wifi icons)
        statusBarIconBrightness: Brightness.light, // Light icons for visibility on teal
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );

    return MaterialApp.router(
      title: 'MRA',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: AppTheme.teal500,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarColor: AppTheme.teal500,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: AnimatedTheme(
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
