class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedDate;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedDate,
  });

  Map<String, dynamic> toSupabase() => {
    'habit_id': habitId,
    'user_id': userId,
    'completed_date': completedDate.toIso8601String().split('T').first,
  };

  factory HabitCompletion.fromSupabase(Map<String, dynamic> map) =>
      HabitCompletion(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        userId: map['user_id'] as String,
        completedDate: DateTime.parse(map['completed_date'] as String),
      );

  /// Returns 'YYYY-MM-DD' string.
  String get dateString =>
      '${completedDate.year}-${completedDate.month.toString().padLeft(2, '0')}-${completedDate.day.toString().padLeft(2, '0')}';
}
