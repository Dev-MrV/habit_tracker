import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_constants.dart';
import 'habit_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(habitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekStats = prov.weeklyStats;
    final maxVal = weekStats.values.isEmpty ? 1.0 : weekStats.values.reduce((a, b) => a > b ? a : b).toDouble();
    final totalHabits = prov.habits.length;
    final completedToday = prov.completedToday.length;
    final completionsThisWeek = prov.totalCompletionsThisWeek;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Reports', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(child: _SummaryCard(label: 'Total Habits', value: '$totalHabits', icon: Icons.track_changes_rounded, color: AppColors.primary)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(label: 'Done Today', value: '$completedToday', icon: Icons.check_circle_rounded, color: AppColors.accentGreen)),
                const SizedBox(width: 16),
                Expanded(child: _SummaryCard(label: 'This Week', value: '$completionsThisWeek', icon: Icons.local_fire_department_rounded, color: AppColors.accentOrange)),
              ],
            ).animate().fade().slideY(begin: 0.1, duration: 400.ms),

            const SizedBox(height: 32),

            // Weekly bar chart
            Text('Weekly Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)).animate().fade(delay: 150.ms),
            const SizedBox(height: 16),

            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(16, 24, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: isDark ? Colors.black26 : AppColors.primary.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal == 0 ? 1 : maxVal) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: isDark ? Colors.white : AppColors.surfaceDark,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()}',
                          TextStyle(color: isDark ? AppColors.surfaceDark : Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 28, interval: 1,
                        getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : AppColors.textLight)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final days = AppConstants.daysOfWeek;
                          final idx = val.toInt();
                          if (idx < 0 || idx >= days.length) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[idx].substring(0, 3), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(color: isDark ? Colors.white10 : Colors.grey.shade200, strokeWidth: 1.5, dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(AppConstants.daysOfWeek.length, (i) {
                    final count = (weekStats[AppConstants.daysOfWeek[i]] ?? 0).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          gradient: LinearGradient(colors: count == 0 ? [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)] : [AppColors.primaryLight, AppColors.primary], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          width: 14,
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true, toY: (maxVal == 0 ? 1 : maxVal) * 1.2,
                            color: isDark ? Colors.white.withOpacity(0.02) : AppColors.primary.withOpacity(0.04),
                          )
                        ),
                      ],
                    );
                  }),
                ),
              ).animate().fade(duration: 800.ms).scaleXY(begin: 0.95),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            // Per-habit breakdown
            Text('Habit Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)).animate().fade(delay: 250.ms),
            const SizedBox(height: 16),

            if (prov.habits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('No habits to report on yet.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ).animate().fade(delay: 300.ms)
            else
              ...prov.habits.asMap().entries.map((entry) {
                final i = entry.key;
                final h = entry.value;
                final color = AppColors.habitColors[h.colorIndex % AppColors.habitColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: isDark ? Colors.black26 : color.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.show_chart_rounded, color: color, size: 22)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(h.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit'))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                              child: Text('${(h.weeklyCompletionRate * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: h.weeklyCompletionRate, minHeight: 10,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ).animate(target: h.weeklyCompletionRate > 0 ? 1 : 0).shimmer(duration: 1000.ms),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.accentOrange),
                                const SizedBox(width: 6),
                                Text('${h.currentStreak} day streak', style: const TextStyle(fontSize: 13, color: AppColors.accentOrange, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(h.isCompletedToday() ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 16, color: h.isCompletedToday() ? AppColors.accentGreen : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(h.isCompletedToday() ? 'Done today' : 'Pending', style: TextStyle(fontSize: 13, color: h.isCompletedToday() ? AppColors.accentGreen : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: Duration(milliseconds: 300 + i * 80)).slideX(begin: 0.1),
                );
              }),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.1), width: 1.5),
        boxShadow: [BoxShadow(color: (isDark ? Colors.black : color).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Outfit')),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}