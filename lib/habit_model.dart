import 'dart:convert';

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int colorIndex;
  final String category;
  final String frequency;
  final List<String> completedDates; // YYYY-MM-DD strings (from habit_completions)
  final bool notificationEnabled;
  final String notificationTime;
  final DateTime createdAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.colorIndex = 0,
    this.category = 'Health',
    this.frequency = 'Daily',
    List<String>? completedDates,
    this.notificationEnabled = false,
    this.notificationTime = 'Morning (7:00 AM)',
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final today = _dateString(DateTime.now());
    return completedDates.contains(today);
  }

  static String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = List<String>.from(completedDates)..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = DateTime.now();
    for (final dateStr in sorted) {
      final date = DateTime.parse(dateStr);
      final diff = current.difference(date).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        current = date;
      } else {
        break;
      }
    }
    return streak;
  }

  List<bool> get weeklyCompletion {
    final result = <bool>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      result.add(completedDates.contains(_dateString(date)));
    }
    return result;
  }

  double get weeklyCompletionRate {
    final weekly = weeklyCompletion;
    return weekly.where((e) => e).length / 7;
  }

  HabitModel withCompletedDates(List<String> dates) =>
      copyWith(completedDates: dates);

  HabitModel toggleToday() {
    final today = _dateString(DateTime.now());
    final updated = List<String>.from(completedDates);
    if (updated.contains(today)) {
      updated.remove(today);
    } else {
      updated.add(today);
    }
    return copyWith(completedDates: updated);
  }

  HabitModel copyWith({
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
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      completedDates: completedDates ?? List.from(this.completedDates),
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      createdAt: createdAt,
    );
  }

  // ─── Supabase (snake_case) ───────────────────────────────
  Map<String, dynamic> toSupabase() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'description': description,
      'color_index': colorIndex,
      'category': category,
      'frequency': frequency,
      'notification_enabled': notificationEnabled,
      'notification_time': notificationTime,
    };
    if (id != 'new' && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Map<String, dynamic> toSupabaseUpdate() => {
    'title': title,
    'description': description,
    'color_index': colorIndex,
    'category': category,
    'frequency': frequency,
    'notification_enabled': notificationEnabled,
    'notification_time': notificationTime,
  };

  factory HabitModel.fromSupabase(Map<String, dynamic> map, {List<String>? completedDates}) =>
      HabitModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String? ?? '',
        description: map['description'] as String?,
        colorIndex: map['color_index'] as int? ?? 0,
        category: map['category'] as String? ?? 'Health',
        frequency: map['frequency'] as String? ?? 'Daily',
        completedDates: completedDates ?? [],
        notificationEnabled: map['notification_enabled'] as bool? ?? false,
        notificationTime: map['notification_time'] as String? ?? 'Morning (7:00 AM)',
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
      );

  // ─── Local Hive cache (camelCase) ──────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'colorIndex': colorIndex,
    'category': category,
    'frequency': frequency,
    'completedDates': completedDates,
    'notificationEnabled': notificationEnabled,
    'notificationTime': notificationTime,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HabitModel.fromMap(Map<String, dynamic> map) => HabitModel(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] as String?,
    colorIndex: map['colorIndex'] ?? 0,
    category: map['category'] ?? 'Health',
    frequency: map['frequency'] ?? 'Daily',
    completedDates: List<String>.from(map['completedDates'] ?? []),
    notificationEnabled: map['notificationEnabled'] ?? false,
    notificationTime: map['notificationTime'] ?? 'Morning (7:00 AM)',
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String)
        : DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory HabitModel.fromJson(String source) =>
      HabitModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}