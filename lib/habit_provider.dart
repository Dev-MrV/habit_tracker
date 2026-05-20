import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'habit_model.dart';
import 'habit_completion_model.dart';
import 'hive_storage.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'app_constants.dart';

class HabitState {
  final List<HabitModel> habits;
  final bool isLoading;
  final String? error;

  HabitState({this.habits = const [], this.isLoading = false, this.error});

  HabitState copyWith({
    List<HabitModel>? habits,
    bool? isLoading,
    String? error,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<HabitModel> get completedToday =>
      habits.where((h) => h.isCompletedToday()).toList();
  List<HabitModel> get pendingToday =>
      habits.where((h) => !h.isCompletedToday()).toList();

  double get todayProgress =>
      habits.isEmpty ? 0 : completedToday.length / habits.length;

  int get totalCompletionsThisWeek {
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      for (final h in habits) {
        if (h.completedDates.contains(dateStr)) total++;
      }
    }
    return total;
  }

  Map<String, int> get weeklyStats {
    final stats = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      int count = 0;
      for (final h in habits) {
        if (h.completedDates.contains(dateStr)) count++;
      }
      stats[AppConstants.daysOfWeek[date.weekday - 1]] = count;
    }
    return stats;
  }

  HabitModel? getBestHabit() {
    if (habits.isEmpty) return null;
    return habits.reduce(
        (a, b) => a.currentStreak >= b.currentStreak ? a : b);
  }
}

class HabitNotifier extends Notifier<HabitState> {
  SupabaseClient get _sb => SupabaseService.client;

  String? get _userId =>
      ref.read(authProvider).currentUser?.id;

  @override
  HabitState build() {
    Future.microtask(_loadHabits);
    return HabitState(isLoading: true);
  }

  // ─── Load habits + completions from Supabase ─────────────
  Future<void> _loadHabits() async {
    final uid = _userId;
    if (uid == null) {
      state = HabitState();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // 1. Fetch habits
      final habitsData = await _sb
          .from('habits')
          .select()
          .eq('user_id', uid)
          .order('created_at');

      // 2. Fetch all completions for this user
      final completionsData = await _sb
          .from('habit_completions')
          .select()
          .eq('user_id', uid);

      // 3. Build completion map: habitId → [dateStrings]
      final completionMap = <String, List<String>>{};
      for (final row in completionsData) {
        final c = HabitCompletion.fromSupabase(row);
        completionMap.putIfAbsent(c.habitId, () => []).add(c.dateString);
      }

      // 4. Assemble HabitModel list
      final habits = (habitsData as List).map((row) {
        final habit = HabitModel.fromSupabase(
          row,
          completedDates: completionMap[row['id']] ?? [],
        );
        return habit;
      }).toList();

      // 5. Cache in Hive for offline reads
      _cacheHabits(habits);

      state = HabitState(habits: habits);
      _syncNotifications(habits);
    } catch (e) {
      // Fallback: load from Hive cache
      final cached = HiveStorage.habitBox.values.toList();
      state = HabitState(habits: cached, error: e.toString());
    }
  }

  void _cacheHabits(List<HabitModel> habits) {
    final box = HiveStorage.habitBox;
    box.clear();
    for (final h in habits) {
      box.put(h.id, h);
    }
  }

  void _syncNotifications(List<HabitModel> habits) {
    try {
      ref.read(notificationProvider.notifier).syncWithHabits(habits);
    } catch (_) {}
  }

  // ─── Reload (call after login) ────────────────────────────
  Future<void> reload() => _loadHabits();

  // ─── Add Habit ───────────────────────────────────────────
  Future<void> addHabit(HabitModel habit) async {
    try {
      final data = await _sb
          .from('habits')
          .insert(habit.toSupabase())
          .select()
          .single();

      final inserted = HabitModel.fromSupabase(
        data,
        completedDates: [],
      );

      final list = [...state.habits, inserted];
      state = state.copyWith(habits: list);
      _cacheHabits(list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Update Habit ─────────────────────────────────────────
  Future<void> updateHabit(HabitModel habit) async {
    try {
      await _sb
          .from('habits')
          .update(habit.toSupabaseUpdate())
          .eq('id', habit.id);

      final list = state.habits
          .map((h) => h.id == habit.id ? habit : h)
          .toList();
      state = state.copyWith(habits: list);
      _cacheHabits(list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Delete Habit ────────────────────────────────────────
  Future<void> deleteHabit(String id) async {
    try {
      await _sb.from('habits').delete().eq('id', id);
      final list = state.habits.where((h) => h.id != id).toList();
      state = state.copyWith(habits: list);
      _cacheHabits(list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ─── Toggle Today's Completion ────────────────────────────
  Future<void> toggleHabitToday(String id) async {
    final uid = _userId;
    if (uid == null) return;

    final habit = state.habits.firstWhere(
      (h) => h.id == id,
      orElse: () => throw Exception('Habit not found'),
    );

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      if (habit.isCompletedToday()) {
        // Remove completion
        await _sb
            .from('habit_completions')
            .delete()
            .eq('habit_id', id)
            .eq('completed_date', todayStr);
      } else {
        // Add completion (upsert to avoid duplicate errors)
        await _sb.from('habit_completions').upsert({
          'habit_id': id,
          'user_id': uid,
          'completed_date': todayStr,
        });
      }

      final updated = habit.toggleToday();
      final list =
          state.habits.map((h) => h.id == id ? updated : h).toList();
      state = state.copyWith(habits: list);
      _cacheHabits(list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final habitProvider =
    NotifierProvider<HabitNotifier, HabitState>(() => HabitNotifier());