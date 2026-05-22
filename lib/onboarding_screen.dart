import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Build Better Habits\nEvery Day',
      description: 'Start your journey towards a more organized, productive, and fulfilled life.',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      title: 'Focus on Action',
      description: 'Create habits, track your daily progress, and build consistency with a single tap.',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.habitColors[0], // blue
    ),
    _OnboardingPageData(
      title: 'Analyze Your Progress',
      description: 'Visualize your success over time with detailed weekly reports and streak tracking.',
      icon: Icons.insert_chart_outlined_rounded,
      color: AppColors.habitColors[1], // green
    ),
    _OnboardingPageData(
      title: 'Smart Reminders',
      description: 'Stay on track with personalized notifications for morning, afternoon, or evening.',
      icon: Icons.notifications_active_outlined,
      color: AppColors.habitColors[2], // purple
    ),
    _OnboardingPageData(
      title: 'Ready to Begin?',
      description: 'Let\'s set up your first habit and build a better you, starting today.',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.habitColors[3], // orange
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Pager
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPageView(
                    page: _pages[index],
                    isDark: isDark,
                  );
                },
              ),
            ),
            
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _AnimatedDot(
                        isActive: index == _currentPage,
                        color: _pages[_currentPage].color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _pages[_currentPage].color.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                     .shimmer(duration: 2.seconds, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPageData page;
  final bool isDark;

  const _OnboardingPageView({
    required this.page,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Icon container
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(isDark ? 0.2 : 0.1),
              border: Border.all(
                color: page.color.withOpacity(isDark ? 0.4 : 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: page.color,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: -8, end: 8, duration: 2.seconds, curve: Curves.easeInOutSine),
          
          const SizedBox(height: 64),
          
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.2,
            ),
          )
          .animate()
          .fade(duration: 500.ms, delay: 100.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          )
          .animate()
          .fade(duration: 500.ms, delay: 250.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _AnimatedDot({
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
