import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'auth_provider.dart';
import 'theme_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'notification_service.dart';
import 'hive_storage.dart';
import 'supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (offline cache)
  await HiveStorage.init();

  // Initialize Supabase (source-of-truth cloud DB)
  await SupabaseService.init();

  // Initialize local notifications
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: HabitFlowApp(),
    ),
  );
}

class HabitFlowApp extends ConsumerWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: _AuthGate(authState: authState),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final AuthState authState;
  const _AuthGate({required this.authState});

  @override
  Widget build(BuildContext context) {
    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight, Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.track_changes_rounded, color: Colors.white, size: 72),
              SizedBox(height: 16),
              Text(
                'HabitFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Build better habits, every day',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
