import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'habit_model.dart';
import 'hive_storage.dart';
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
  @override
  HabitState build() {
    Future.microtask(_loadHabits);
    return HabitState(isLoading: true);
  }

  /// Load habits from local Hive storage
  Future<void> _loadHabits() async {
    try {
      final box = HiveStorage.habitBox;
      final habits = box.values.toList();
      state = HabitState(habits: habits);
      _syncNotifications(habits);
    } catch (e) {
      state = HabitState(error: 'Failed to load habits: $e');
    }
  }

  void _syncNotifications(List<HabitModel> habits) {
    try {
      ref.read(notificationProvider.notifier).syncWithHabits(habits);
    } catch (_) {}
  }

  /// Reload habits from storage
  Future<void> reload() => _loadHabits();

  /// Add a new habit
  Future<void> addHabit(HabitModel habit) async {
    try {
      const userId = 'local_user';
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      final newHabit = HabitModel(
        id: id,
        userId: userId,
        title: habit.title,
        description: habit.description,
        colorIndex: habit.colorIndex,
        category: habit.category,
        frequency: habit.frequency,
        completedDates: [],
        notificationEnabled: habit.notificationEnabled,
        notificationTime: habit.notificationTime,
      );

      final box = HiveStorage.habitBox;
      await box.put(id, newHabit);

      final list = [...state.habits, newHabit];
      state = state.copyWith(habits: list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add habit: $e');
    }
  }

  /// Update an existing habit
  Future<void> updateHabit(HabitModel habit) async {
    try {
      final box = HiveStorage.habitBox;
      await box.put(habit.id, habit);

      final list = state.habits
          .map((h) => h.id == habit.id ? habit : h)
          .toList();
      state = state.copyWith(habits: list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update habit: $e');
    }
  }

  /// Delete a habit
  Future<void> deleteHabit(String id) async {
    try {
      final box = HiveStorage.habitBox;
      await box.delete(id);

      final list = state.habits.where((h) => h.id != id).toList();
      state = state.copyWith(habits: list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete habit: $e');
    }
  }

  /// Toggle today's completion for a habit
  Future<void> toggleHabitToday(String id) async {
    try {
      final habit = state.habits.firstWhere(
        (h) => h.id == id,
        orElse: () => throw Exception('Habit not found'),
      );

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      List<String> newDates;
      if (habit.isCompletedToday()) {
        // Remove completion for today
        newDates = habit.completedDates
            .where((d) => d != todayStr)
            .toList();
      } else {
        // Add completion for today
        newDates = [...habit.completedDates, todayStr];
      }

      final updated = habit.copyWith(completedDates: newDates);
      final box = HiveStorage.habitBox;
      await box.put(id, updated);

      final list = state.habits
          .map((h) => h.id == id ? updated : h)
          .toList();
      state = state.copyWith(habits: list);
      _syncNotifications(list);
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle habit: $e');
    }
  }

  /// Export habits data to JSON (for backup)
  Map<String, dynamic> exportToJson() {
    return {
      'habits': state.habits.map((h) => h.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import habits from JSON (for restore)
  Future<void> importFromJson(Map<String, dynamic> data) async {
    try {
      final box = HiveStorage.habitBox;
      await box.clear();

      if (data['habits'] is List) {
        for (final habitData in data['habits'] as List) {
          final habit = HabitModel.fromMap(habitData);
          await box.put(habit.id, habit);
        }
      }

      await _loadHabits();
    } catch (e) {
      state = state.copyWith(error: 'Failed to import habits: $e');
    }
  }
}

extension on HabitModel {
  HabitModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? colorIndex,
    String? category,
    String? frequency,
    List<String>? completedDates,
    bool? notificationEnabled,
    String? notificationTime,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      completedDates: completedDates ?? this.completedDates,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }

  HabitModel toggleToday() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final newDates = isCompletedToday()
        ? completedDates.where((d) => d != todayStr).toList()
        : [...completedDates, todayStr];
    
    return copyWith(completedDates: newDates);
  }
}

final habitProvider =
    NotifierProvider<HabitNotifier, HabitState>(() => HabitNotifier());