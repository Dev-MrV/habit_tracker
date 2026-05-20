import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'notification_provider.dart';
import 'habit_provider.dart';
import 'animated_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationProvider);
    final habits = ref.watch(habitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global toggle card
            AnimatedContainer(
              duration: const Duration(milliseconds: 500), curve: Curves.easeOutExpo,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: notifs.globalEnabled ? [AppColors.primary, AppColors.primaryLight] : [isDark ? AppColors.cardDark : Colors.grey.shade100, isDark ? AppColors.surfaceDark : Colors.grey.shade50],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: notifs.globalEnabled ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(notifs.globalEnabled ? 0.25 : 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Icon(notifs.globalEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: notifs.globalEnabled ? Colors.white : (isDark ? Colors.white54 : Colors.grey), size: 30)
                        .animate(target: notifs.globalEnabled ? 1 : 0).shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Notifications', style: TextStyle(color: notifs.globalEnabled ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary), fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Outfit')),
                        const SizedBox(height: 4),
                        Text(notifs.globalEnabled ? 'Reminders are active' : 'All reminders paused', style: TextStyle(color: notifs.globalEnabled ? Colors.white70 : (isDark ? Colors.white38 : AppColors.textSecondary), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Switch(
                    value: notifs.globalEnabled,
                    onChanged: (_) => ref.read(notificationProvider.notifier).toggleGlobal(),
                    activeColor: Colors.white, activeTrackColor: Colors.white.withOpacity(0.4),
                    inactiveThumbColor: isDark ? Colors.grey : Colors.white, inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 36),

            Text('Per-Habit Reminders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)).animate().fade(delay: 150.ms),
            const SizedBox(height: 8),
            Text('Configure individual reminder times per habit', style: Theme.of(context).textTheme.bodyMedium).animate().fade(delay: 200.ms),
            const SizedBox(height: 20),

            if (habits.habits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, size: 50, color: AppColors.primary)),
                      const SizedBox(height: 20),
                      Text('No habits to notify.', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ).animate().fade(delay: 250.ms)
            else
              ...List.generate(notifs.settings.length, (i) {
                final setting = notifs.settings[i];
                final habitMatch = habits.habits.where((h) => h.id == setting.habitId);
                if (habitMatch.isEmpty) return const SizedBox.shrink();
                final habit = habitMatch.first;
                final color = AppColors.habitColors[habit.colorIndex % AppColors.habitColors.length];
                final ef = notifs.globalEnabled && setting.enabled;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuad,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: ef ? Border.all(color: color.withOpacity(0.4), width: 2) : Border.all(color: Colors.transparent, width: 2),
                    boxShadow: [BoxShadow(color: ef ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: ef ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.notifications_rounded, color: ef ? color : Colors.grey.withOpacity(0.5), size: 24),
                        ),
                        title: Text(setting.habitTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit', color: isDark ? Colors.white : AppColors.textPrimary)),
                        subtitle: AnimatedOpacity(
                          opacity: ef ? 1.0 : 0.5, duration: const Duration(milliseconds: 300),
                          child: Text(setting.time, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        trailing: Switch(
                          value: setting.enabled,
                          onChanged: notifs.globalEnabled ? (_) => ref.read(notificationProvider.notifier).toggleHabitNotification(setting.habitId) : null,
                          activeColor: color, activeTrackColor: color.withOpacity(0.3),
                        ),
                      ),
                      if (setting.enabled && notifs.globalEnabled) ...[
                        const Divider(height: 1, indent: 20, endIndent: 20, thickness: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 10),
                              AnimatedPressButton(
                                onTap: () async {
                                  int currHour = 7; int currMin = 0;
                                  final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(setting.time);
                                  if (match != null) {
                                    currHour = int.parse(match.group(1)!); currMin = int.parse(match.group(2)!);
                                    if (match.group(3) == 'PM' && currHour != 12) currHour += 12;
                                    if (match.group(3) == 'AM' && currHour == 12) currHour = 0;
                                  }
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay(hour: currHour, minute: currMin));
                                  if (time != null) {
                                    String period = time.period == DayPeriod.am ? 'AM' : 'PM';
                                    int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                    String minute = time.minute.toString().padLeft(2, '0');
                                    ref.read(notificationProvider.notifier).setHabitTime(setting.habitId, 'Custom ($hour:$minute $period)');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_filled_rounded, color: color, size: 18),
                                      const SizedBox(width: 8),
                                      Text(setting.time, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.edit_rounded, color: color, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fade(delay: Duration(milliseconds: 250 + i * 80)).slideX(begin: 0.05);
              }),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}