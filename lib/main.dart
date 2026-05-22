import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'theme_provider.dart';
import 'notification_service.dart';
import 'hive_storage.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load preferences for onboarding check
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('has_completed_onboarding') ?? false);

  // Initialize Hive (offline-first local storage)
  await HiveStorage.init();

  // Initialize local notifications
  await NotificationService.init();

  runApp(
    ProviderScope(
      child: HabitFlowApp(showOnboarding: showOnboarding),
    ),
  );
}

class HabitFlowApp extends ConsumerWidget {
  final bool showOnboarding;
  
  const HabitFlowApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: showOnboarding ? const OnboardingScreen() : const MainShell(),
    );
  }
}
