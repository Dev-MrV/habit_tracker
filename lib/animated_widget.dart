import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade + slide up animation wrapper using flutter_animate
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(delay: delay)
        .fade(duration: duration, curve: Curves.easeOutQuad)
        .slideY(begin: 0.15, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }
}

/// Gradient button with loading state and premium scale interaction
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final List<Color>? colors;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = colors ?? const [Color(0xFF0D9488), Color(0xFF10B981)];
    return AnimatedPressButton(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradColors.first.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ).animate().fade().scale()
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ).animate().moveY(begin: 5, end: 0, duration: 300.ms).fade(),
      ),
    );
  }
}

/// Animated press (scale) wrapper for micro-interactions
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedPressButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Shimmering placeholder using flutter_animate
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1200.ms,
      color: isDark ? Colors.white12 : Colors.white60,
    );
  }
}