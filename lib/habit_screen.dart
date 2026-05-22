import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_constants.dart';
import 'habit_provider.dart';
import 'habit_model.dart';
import 'animated_widget.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(habitProvider);

    return Scaffold(
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          onPressed: () => _showAddHabitDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Text('${prov.habits.length} habits', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.habits.isEmpty
              ? _EmptyState(onAdd: () => _showAddHabitDialog(context))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  itemCount: prov.habits.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: InkWell(
                          onTap: () => _showAddHabitDialog(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                                const SizedBox(width: 8),
                                Text('Add New Habit', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade().slideY(begin: -0.1);
                    }

                    final h = prov.habits[i - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _HabitCard(
                        habit: h,
                        onToggle: () => ref.read(habitProvider.notifier).toggleHabitToday(h.id),
                        onDelete: () => _confirmDelete(context, h),
                        onEdit: () => _showEditDialog(context, h),
                      ),
                    ).animate().fade(delay: Duration(milliseconds: (i - 1) * 80)).slideY(begin: 0.1, curve: Curves.easeOutQuad);
                  },
                ),
    );
  }

  void _confirmDelete(BuildContext ctx, HabitModel habit) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Habit?'),
        content: Text('Delete "${habit.title}"? This cannot be undone.', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) => _showHabitDialog(context, null);
  void _showEditDialog(BuildContext context, HabitModel habit) => _showHabitDialog(context, habit);

  void _showHabitDialog(BuildContext context, HabitModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitFormSheet(existing: existing),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitModel habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _HabitCard({required this.habit, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.habitColors[habit.colorIndex % AppColors.habitColors.length];
    final done = habit.isCompletedToday();
    final streak = habit.currentStreak;

    return Slidable(
      key: ValueKey(habit.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
        ],
      ),
      child: AnimatedPressButton(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: done ? color.withOpacity(isDark ? 0.2 : 0.08) : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: done ? color.withOpacity(0.6) : Colors.transparent, width: 2),
            boxShadow: [
              if (!done) BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
              if (done) BoxShadow(color: color.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: done ? color : color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: done ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16)] : [],
                ),
                child: Icon(done ? Icons.check_rounded : Icons.star_border_rounded, color: done ? Colors.white : color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              fontFamily: 'Outfit',
                              decoration: done ? TextDecoration.lineThrough : null,
                              decorationColor: color,
                              color: done ? (isDark ? Colors.white54 : Colors.black54) : (isDark ? Colors.white : AppColors.textPrimary),
                            ),
                            child: Text(habit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(habitProvider.notifier).updateHabit(
                              habit.copyWith(notificationEnabled: !habit.notificationEnabled),
                            );
                          },
                          icon: Icon(
                            habit.notificationEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                            size: 20,
                            color: habit.notificationEnabled ? color : Colors.grey.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(habit.category, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        if (streak > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.accentOrange),
                              const SizedBox(width: 4),
                              Text('$streak d', style: const TextStyle(fontSize: 13, color: AppColors.accentOrange, fontWeight: FontWeight.w800)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Wrap(
                    spacing: 4,
                    children: habit.weeklyCompletion.map((c) => Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c ? color : (isDark ? Colors.white12 : Colors.grey.shade200)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text('${(habit.weeklyCompletionRate * 100).round()}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.1)),
            child: const Icon(Icons.rocket_launch_rounded, size: 64, color: AppColors.primary),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 3.seconds),
          const SizedBox(height: 32),
          Text('Ready to level up?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Tracking leads to achieving.\nStart your first habit building process now.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ).animate().fade().scaleXY(begin: 0.9),
    );
  }
}

class _HabitFormSheet extends ConsumerStatefulWidget {
  final HabitModel? existing;
  const _HabitFormSheet({this.existing});
  @override
  ConsumerState<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<_HabitFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Health';
  String _frequency = 'Daily';
  int _colorIndex = 0;
  bool _notificationEnabled = false;
  String _notificationTime = 'Morning (7:00 AM)';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final h = widget.existing!;
      _titleCtrl.text = h.title;
      _descCtrl.text = h.description ?? '';
      _category = h.category;
      _frequency = h.frequency;
      _colorIndex = h.colorIndex;
      _notificationEnabled = h.notificationEnabled;
      _notificationTime = h.notificationTime;
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _pickTime() async {
    int currHour = 7; int currMin = 0;
    final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(_notificationTime);
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
      setState(() => _notificationTime = 'Custom ($hour:$minute $period)');
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final prov = ref.read(habitProvider.notifier);

    if (widget.existing != null) {
      await prov.updateHabit(widget.existing!.copyWith(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(), colorIndex: _colorIndex, category: _category, frequency: _frequency, notificationEnabled: _notificationEnabled, notificationTime: _notificationTime));
    } else {
      await prov.addHabit(HabitModel(id: 'new', userId: 'local_user', title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(), colorIndex: _colorIndex, category: _category, frequency: _frequency, notificationEnabled: _notificationEnabled, notificationTime: _notificationTime));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 48, height: 6, margin: const EdgeInsets.only(bottom: 32), decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(6)))),
              Text(widget.existing != null ? 'Edit Habit' : 'New Habit', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),

              TextFormField(controller: _titleCtrl, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), decoration: const InputDecoration(labelText: 'Habit Name *', prefixIcon: Icon(Icons.edit_rounded))),
              const SizedBox(height: 16),
              TextFormField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes_rounded))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
                items: AppConstants.habitCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency, decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.repeat_rounded)),
                items: AppConstants.habitFrequencies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              
              const SizedBox(height: 24),
              Text('Theme Color', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: List.generate(AppColors.habitColors.length, (i) {
                  final c = AppColors.habitColors[i];
                  final sel = i == _colorIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: sel ? 42 : 36, height: sel ? 42 : 36,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3), boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 12, offset: const Offset(0, 6))] : []),
                      child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.habitColors[_colorIndex % AppColors.habitColors.length].withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enable Reminders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Switch(value: _notificationEnabled, onChanged: (v) => setState(() => _notificationEnabled = v), activeColor: AppColors.habitColors[_colorIndex % AppColors.habitColors.length]),
                      ],
                    ),
                    if (_notificationEnabled) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
                          AnimatedPressButton(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.habitColors[_colorIndex % AppColors.habitColors.length].withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text(_notificationTime, style: TextStyle(color: AppColors.habitColors[_colorIndex % AppColors.habitColors.length], fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 36),
              GradientButton(label: widget.existing != null ? 'Save Changes' : 'Create Habit', colors: [AppColors.habitColors[_colorIndex % AppColors.habitColors.length], AppColors.habitColors[_colorIndex % AppColors.habitColors.length].withOpacity(0.8)], onTap: _save),
            ],
          ),
        ),
      ),
    );
  }
}