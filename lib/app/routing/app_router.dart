import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/modern_login_screen.dart';
import '../../features/auth/presentation/modern_signup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/medication/presentation/add_medication_screen.dart';
import '../../features/medication/presentation/medication_list_screen.dart';
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
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: NotificationsService.navigatorKey,
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const ModernLoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const ModernSignUpScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/medications',
      builder: (context, state) => const MedicationListScreen(),
    ),
    GoRoute(
      path: '/medications/add',
      builder: (context, state) {
        final medication = state.extra as Medication?;
        return AddMedicationScreen(medication: medication);
      },
    ),
    GoRoute(
      path: '/tips',
      builder: (context, state) => const TipsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/logs/:medicationId',
      builder: (context, state) {
        final medicationId = state.pathParameters['medicationId']!;
        return LogMedicationScreen(medicationId: medicationId);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) => const ExportScreen(),
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentListScreen(),
    ),
    GoRoute(
      path: '/appointments/add',
      builder: (context, state) {
        final appointment = state.extra as Appointment?;
        return AddAppointmentScreen(appointment: appointment);
      },
    ),
    GoRoute(
      path: '/appointments/:id',
      builder: (context, state) {
        final appointmentId = state.pathParameters['id']!;
        return AppointmentDetailScreen(appointmentId: appointmentId);
      },
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/medical-history',
      builder: (context, state) => const MedicalHistoryScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) => const PrivacyDataScreen(),
    ),
  ],
);


