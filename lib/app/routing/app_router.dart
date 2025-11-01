import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/modern_login_screen.dart';
import '../../features/auth/presentation/modern_signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/medication/presentation/add_medication_screen.dart';
import '../../features/medication/presentation/medication_list_screen.dart';
import '../../features/medication/presentation/medication_details_screen.dart';
import '../../features/tips/presentation/tips_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/logs/presentation/log_medication_screen.dart';
import '../../features/logs/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/export/presentation/export_screen.dart';
import '../../features/appointments/presentation/appointment_list_screen.dart';
import '../../features/appointments/presentation/add_appointment_screen.dart';
import '../../features/appointments/presentation/appointment_detail_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/medical_history_screen.dart';
import '../../features/profile/presentation/privacy_data_screen.dart';
import '../../core/models/medication.dart';
import '../../core/models/appointment.dart';
import '../../core/services/notifications_service.dart';
import '../../app/theme/app_theme.dart';

/// Navigation observer that ensures system UI overlay style remains consistent
class _SystemUIOverlayObserver extends NavigatorObserver {
  void _setTealSystemUI() {
    // Use post-frame callback to ensure it runs after route transition completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: AppTheme.teal500,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: AppTheme.teal500,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setTealSystemUI();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _setTealSystemUI();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _setTealSystemUI();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _setTealSystemUI();
  }
}

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user != null) {
            context.go('/');
          } else {
            context.go('/welcome');
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CustomTransitionPage<T> _buildPageWithDefaultTransition<T>(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: NotificationsService.navigatorKey,
  redirect: (context, state) {
    // Prevent navigation issues
    return null;
  },
  observers: [
    _SystemUIOverlayObserver(),
  ],
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const WelcomeScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const ModernLoginScreen(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const ModernSignUpScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const DashboardScreen()),
    ),
    GoRoute(
      path: '/medications',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const MedicationListScreen(),
      ),
    ),
    GoRoute(
      path: '/medications/add',
      pageBuilder: (context, state) {
        final medication = state.extra as Medication?;
        return _buildPageWithDefaultTransition<void>(
          state,
          AddMedicationScreen(medication: medication),
        );
      },
    ),
    GoRoute(
      path: '/medications/:id/details',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final medication = extra?['medication'] as Medication? ??
            (state.extra as Medication?);
        final scheduledTime = extra?['scheduledTime'] as DateTime?;
        
        if (medication == null) {
          // Fallback: try to get from medication list if needed
          return _buildPageWithDefaultTransition<void>(
            state,
            const Scaffold(
              body: Center(child: Text('Medication not found')),
            ),
          );
        }
        
        return _buildPageWithDefaultTransition<void>(
          state,
          MedicationDetailsScreen(
            medication: medication,
            scheduledTime: scheduledTime,
          ),
        );
      },
    ),
    GoRoute(
      path: '/tips',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const TipsScreen()),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const ProfileScreen()),
    ),
    GoRoute(
      path: '/logs/:medicationId',
      pageBuilder: (context, state) {
        final medicationId = state.pathParameters['medicationId']!;
        return _buildPageWithDefaultTransition<void>(
          state,
          LogMedicationScreen(medicationId: medicationId),
        );
      },
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const HistoryScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/analytics',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const AnalyticsScreen()),
    ),
    GoRoute(
      path: '/achievements',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const AchievementsScreen(),
      ),
    ),
    GoRoute(
      path: '/export',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const ExportScreen()),
    ),
    GoRoute(
      path: '/appointments',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const AppointmentListScreen(),
      ),
    ),
    GoRoute(
      path: '/appointments/add',
      pageBuilder: (context, state) {
        final appointment = state.extra as Appointment?;
        return _buildPageWithDefaultTransition<void>(
          state,
          AddAppointmentScreen(appointment: appointment),
        );
      },
    ),
    GoRoute(
      path: '/appointments/:id',
      pageBuilder: (context, state) {
        final appointmentId = state.pathParameters['id']!;
        return _buildPageWithDefaultTransition<void>(
          state,
          AppointmentDetailScreen(appointmentId: appointmentId),
        );
      },
    ),
    GoRoute(
      path: '/emergency',
      pageBuilder: (context, state) =>
          _buildPageWithDefaultTransition<void>(state, const EmergencyScreen()),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/medical-history',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const MedicalHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/privacy',
      pageBuilder: (context, state) => _buildPageWithDefaultTransition<void>(
        state,
        const PrivacyDataScreen(),
      ),
    ),
  ],
);
