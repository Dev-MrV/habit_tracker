import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'auth_provider.dart';
import 'habit_provider.dart';
import 'animated_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final habitProv = ref.watch(habitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.currentUser;
    final firstName = user?.name.split(' ').first ?? 'there';

    final total = habitProv.habits.length;
    final completed = habitProv.completedToday.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Ambient Slivers Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.backgroundDark,
            flexibleSpace: LayoutBuilder(
              builder: (ctx, constraints) {
                final isCollapsed = constraints.biggest.height <= MediaQuery.of(ctx).padding.top + kToolbarHeight + 10;
                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: isCollapsed
                      ? Text(_greeting(), style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Colors.white)).animate().fade()
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                      Positioned(
                        top: -50, right: -50,
                        child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))
                            .animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.2, duration: 4.seconds),
                      ),
                      Positioned(
                        bottom: -40, left: -40,
                        child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.2)))
                            .animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -30, duration: 5.seconds),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(28, MediaQuery.of(ctx).padding.top + 30, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting(), style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)).animate().fade().slideY(begin: -0.2),
                            const SizedBox(height: 6),
                            Text('$firstName 👋', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5)).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                            const SizedBox(height: 8),
                            const Text('Small habits build great futures.', style: TextStyle(color: Colors.white70, fontSize: 15)).animate().fade(delay: 200.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Modern Progress card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: isDark ? Colors.black26 : AppColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Progress", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                          Text('${(progress * 100).round()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 14,
                          backgroundColor: isDark ? AppColors.inputFillDark : AppColors.inputFill,
                          valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? AppColors.accentGreen : AppColors.primary),
                        ),
                      ).animate(target: progress).shimmer(duration: 800.ms),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(icon: Icons.check_circle_rounded, label: '$completed Done', color: AppColors.accentGreen),
                          _StatChip(icon: Icons.radio_button_unchecked_rounded, label: '${total - completed} Left', color: AppColors.accentOrange),
                          _StatChip(icon: Icons.local_fire_department_rounded, label: '${habitProv.getBestHabit()?.currentStreak ?? 0}d Streak', color: AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(duration: 500.ms).scaleXY(begin: 0.95),

                const SizedBox(height: 32),

                // Weekly overview
                Text("This Week", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)).animate().fade(delay: 150.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: isDark ? Colors.black26 : AppColors.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: _WeeklyDots(habitProv: habitProv),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                // Pending habits
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Habits", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text('$completed / $total', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ).animate().fade(delay: 250.ms),
                
                const SizedBox(height: 16),

                if (habitProv.isLoading)
                  ...List.generate(3, (i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: const ShimmerBox(width: double.infinity, height: 80, radius: 24)))
                else if (habitProv.habits.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(Icons.add_task_rounded, size: 50, color: AppColors.textPrimary),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 4.seconds),
                          const SizedBox(height: 16),
                          Text('No habits found', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 300.ms)
                else
                  ...habitProv.habits.asMap().entries.map((entry) {
                    final i = entry.key;
                    final h = entry.value;
                    final color = AppColors.habitColors[h.colorIndex % AppColors.habitColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HabitTile(
                        habit: h,
                        color: color,
                        onToggle: () => ref.read(habitProvider.notifier).toggleHabitToday(h.id),
                      ),
                    ).animate().fade(delay: Duration(milliseconds: 300 + (i * 80))).slideX(begin: 0.1);
                  }),

                // Completed section message
                if (progress >= 1.0 && total > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accentGreen.withOpacity(0.2), AppColors.accentGreen.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.accentGreen.withOpacity(0.4), blurRadius: 16)]),
                          child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 28),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.1, duration: 1.seconds),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Perfect Day!', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w800, fontSize: 18)),
                              Text('All habits completed.', style: TextStyle(color: AppColors.accentGreen, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().scaleXY(begin: 0.8, curve: Curves.easeOutBack, duration: 600.ms),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final dynamic habit;
  final Color color;
  final VoidCallback onToggle;

  const _HabitTile({required this.habit, required this.color, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = habit.isCompletedToday();

    return AnimatedPressButton(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? color.withOpacity(isDark ? 0.15 : 0.08) : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: done ? color.withOpacity(0.6) : Colors.transparent, width: 2),
          boxShadow: [
            if (!done) BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
            if (done) BoxShadow(color: color.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: done ? color : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                boxShadow: done ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)] : [],
              ),
              child: Icon(done ? Icons.check_rounded : Icons.radio_button_unchecked_rounded, color: done ? Colors.white : color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? (isDark ? Colors.white54 : Colors.black54) : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    child: Text(habit.title),
                  ),
                  const SizedBox(height: 2),
                  if (habit.description != null && habit.description!.isNotEmpty)
                    Text(habit.description!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeeklyDots extends StatelessWidget {
  final HabitState habitProv;
  const _WeeklyDots({required this.habitProv});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final stats = habitProv.weeklyStats;
    final maxHabits = habitProv.habits.isNotEmpty ? habitProv.habits.length : 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final dayLabel = days[i];
        final key = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
        final count = stats[key] ?? 0;
        final pct = count / maxHabits;
        final isToday = i == (DateTime.now().weekday - 1);

        return Column(
          children: [
            Container(
              width: 36, height: 60,
              decoration: BoxDecoration(color: isToday ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800), curve: Curves.easeOutCirc,
                width: 24, height: (60 * pct).clamp(6, 60),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: pct >= 1.0 ? [AppColors.accentGreen, AppColors.accentGreen] : [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: pct > 0 ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(dayLabel, style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? AppColors.primary : AppColors.textSecondary)),
          ],
        );
      }),
    );
  }
}
