import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_constants.dart';
import 'auth_provider.dart';
import 'animated_widget.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _country = 'United States';
  bool _obscure = true;
  bool _obscureConfirm = true;
  int _strengthScore = 0;
  String _strengthLabel = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String v) {
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    setState(() {
      _strengthScore = score;
      _strengthLabel = score > 0 ? labels[score - 1] : '';
    });
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.primaryLight;
      case 4: return AppColors.success;
      default: return Colors.grey;
    }
  }

  Future<void> _register() async {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.length < 2) {
      _showSnack('Please enter your full name (min 2 chars)');
      return;
    }
    if (username.length < 3) {
      _showSnack('Username must be at least 3 characters');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }
    if (age < 1 || age > 120) {
      _showSnack('Please enter a valid age');
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    final success = await authNotifier.register(
      name: name,
      username: username,
      email: email,
      age: age,
      country: _country,
      password: password,
    );

    if (success && mounted) {
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.warning,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 100)]
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 7.seconds, curve: Curves.easeInOut)
             .moveY(end: 40, duration: 5.seconds),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),

                    // Header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 40),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -4, end: 4, duration: 4.seconds, curve: Curves.easeInOut),
                    ).animate().fade(duration: 600.ms).scaleXY(begin: 0.8),
                    
                    const SizedBox(height: 24),
                    Text('Create Account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall)
                      .animate().fade(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    Text('Join thousands building better habits', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)
                      .animate().fade(delay: 200.ms),

                    const SizedBox(height: 32),

                    // Error banner
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: authState.errorMessage != null
                          ? Container(
                              key: ValueKey(authState.errorMessage),
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(authState.errorMessage!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ).animate().shake(hz: 6, duration: 300.ms).fade()
                          : const SizedBox.shrink(),
                    ),

                    // Form
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                    ).animate().fade(delay: 250.ms).slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded)),
                    ).animate().fade(delay: 300.ms).slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    ).animate().fade(delay: 350.ms).slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
                    ).animate().fade(delay: 400.ms).slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _country,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public_rounded)),
                      items: kCountries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _country = v!),
                    ).animate().fade(delay: 450.ms).slideX(begin: 0.05),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onChanged: _checkStrength,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms).slideX(begin: 0.05),

                    // Strength indicator
                    if (_strengthScore > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(4, (i) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i < _strengthScore ? _strengthColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )),
                      ).animate().fade(),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Strength: $_strengthLabel',
                          style: TextStyle(color: _strengthColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ).animate().fade(),
                    ],

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ).animate().fade(delay: 550.ms).slideX(begin: 0.05),

                    const SizedBox(height: 36),

                    GradientButton(
                      label: 'Create Account',
                      onTap: _register,
                      isLoading: isLoading,
                    ).animate().fade(delay: 600.ms).scaleXY(begin: 0.95),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, a, b) => const LoginScreen(),
                              transitionsBuilder: (_, a, b, child) => FadeTransition(opacity: a, child: child),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 700.ms),

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