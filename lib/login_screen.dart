import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'auth_provider.dart';
import 'animated_widget.dart';
import 'register_screen.dart';
import 'main_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  ValueKey<int> _shakeKey = const ValueKey(0);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _triggerShake() {
    setState(() {
      _shakeKey = ValueKey(_shakeKey.value + 1);
    });
  }

  Future<void> _login() async {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      _triggerShake();
      return;
    }

    final success = await authNotifier.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!success && mounted) {
      _triggerShake();
    } else if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const MainShell(),
          transitionsBuilder: (_, a, b, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(authProvider.notifier).resetPassword(emailCtrl.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Password reset link sent!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(20),
                ));
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Background Blobs
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.08),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 100)]
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 6.seconds, curve: Curves.easeInOut)
             .moveX(end: -40, duration: 5.seconds),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(isDark ? 0.15 : 0.05),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.15), blurRadius: 100)]
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 5.seconds, curve: Curves.easeInOut)
             .moveY(end: -30, duration: 4.seconds),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Floating App Icon
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 48),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .moveY(begin: -6, end: 6, duration: 3.seconds, curve: Curves.easeInOut),
                    ).animate().fade(duration: 800.ms).scaleXY(begin: 0.8, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 32),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue your journey',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 48),

                    // Glassmorphism Error Banner
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: authState.errorMessage != null
                          ? ClipRRect(
                              key: ValueKey(authState.errorMessage),
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.2), shape: BoxShape.circle),
                                        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fade().slideY(begin: -0.1)
                          : const SizedBox.shrink(),
                    ),

                    // Inputs
                    Container(
                      key: _shakeKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          ).animate().fade(delay: 400.ms).slideX(begin: 0.05),
                          
                          const SizedBox(height: 18),
                          
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ).animate().fade(delay: 500.ms).slideX(begin: 0.05),
                        ],
                      ),
                    ).animate(key: _shakeKey).shake(hz: 8, curve: Curves.easeInOutCubic, duration: 500.ms),

                    const SizedBox(height: 36),

                    GradientButton(
                      label: 'Sign In',
                      onTap: _login,
                      isLoading: isLoading,
                    ).animate().fade(delay: 600.ms).scaleXY(begin: 0.95),

                    const SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ).animate().fade(delay: 700.ms),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, a, b) => const RegisterScreen(),
                              transitionsBuilder: (_, a, b, child) => FadeTransition(opacity: a, child: child),
                            ),
                          ),
                          child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ],
                    ).animate().fade(delay: 800.ms),
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}