import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_provider.dart';
import 'habit_model.dart';
import 'notification_service.dart';

class NotificationSetting {
  final String habitId;
  final String habitTitle;
  bool enabled;
  String time;

  NotificationSetting({
    required this.habitId,
    required this.habitTitle,
    this.enabled = true,
    this.time = 'Morning (7:00 AM)',
  });

  Map<String, dynamic> toMap() => {
        'habitId': habitId,
        'habitTitle': habitTitle,
        'enabled': enabled,
        'time': time,
      };

  factory NotificationSetting.fromMap(Map<String, dynamic> map) =>
      NotificationSetting(
        habitId: map['habitId'] ?? '',
        habitTitle: map['habitTitle'] ?? '',
        enabled: map['enabled'] ?? true,
        time: map['time'] ?? 'Morning (7:00 AM)',
      );
}

class NotificationState {
  final bool globalEnabled;
  final List<NotificationSetting> settings;
  NotificationState({this.globalEnabled = true, this.settings = const []});

  NotificationState copyWith({
    bool? globalEnabled,
    List<NotificationSetting>? settings,
  }) {
    return NotificationState(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      settings: settings ?? this.settings,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  SupabaseClient get _sb => SupabaseService.client;
  String? get _userId => ref.read(authProvider).currentUser?.id;

  @override
  NotificationState build() {
    Future.microtask(_load);
    return NotificationState();
  }

  Map<String, int> _parseTime(String time) {
    final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(time);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!;
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return {'hour': hour, 'minute': minute};
    }
    return {'hour': 7, 'minute': 0};
  }

  Future<void> _load() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final data = await _sb
          .from('notification_preferences')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (data != null) {
        final globalEnabled = data['global_enabled'] as bool? ?? true;
        final rawSettings = data['settings'];
        List<NotificationSetting> settings = [];
        if (rawSettings != null) {
          final list = (rawSettings is String
              ? jsonDecode(rawSettings)
              : rawSettings) as List<dynamic>;
          settings = list
              .map((e) => NotificationSetting.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        state = NotificationState(globalEnabled: globalEnabled, settings: settings);
        _rescheduleAll();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _sb.from('notification_preferences').upsert({
        'user_id': uid,
        'global_enabled': state.globalEnabled,
        'settings': jsonEncode(state.settings.map((s) => s.toMap()).toList()),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _rescheduleAll() async {
    if (!state.globalEnabled) return;
    for (var s in state.settings) {
      if (s.enabled) {
        final t = _parseTime(s.time);
        await NotificationService.scheduleNotification(
          id: s.habitId.hashCode,
          title: s.habitTitle,
          body: 'Time to complete your habit!',
          hour: t['hour']!,
          minute: t['minute']!,
        );
      }
    }
  }

  void syncWithHabits(List<HabitModel> habits) {
    var settings = List<NotificationSetting>.from(state.settings);
    for (final habit in habits) {
      final exists = settings.any((s) => s.habitId == habit.id);
      if (!exists) {
        final newSetting = NotificationSetting(
          habitId: habit.id,
          habitTitle: habit.title,
          enabled: habit.notificationEnabled,
          time: habit.notificationTime,
        );
        settings.add(newSetting);
        if (state.globalEnabled && newSetting.enabled) {
          final t = _parseTime(newSetting.time);
          NotificationService.scheduleNotification(
            id: newSetting.habitId.hashCode,
            title: newSetting.habitTitle,
            body: 'Time to complete your habit!',
            hour: t['hour']!,
            minute: t['minute']!,
          );
        }
      }
    }
    settings.removeWhere((s) => !habits.any((h) => h.id == s.habitId));
    state = state.copyWith(settings: settings);
    _save();
  }

  Future<void> toggleGlobal() async {
    state = state.copyWith(globalEnabled: !state.globalEnabled);
    if (!state.globalEnabled) {
      for (var s in state.settings) {
        await NotificationService.cancelNotification(s.habitId.hashCode);
      }
    } else {
      await _rescheduleAll();
    }
    await _save();
  }

  Future<void> toggleHabitNotification(String habitId) async {
    final settings = List<NotificationSetting>.from(state.settings);
    final idx = settings.indexWhere((s) => s.habitId == habitId);
    if (idx != -1) {
      settings[idx].enabled = !settings[idx].enabled;
      state = state.copyWith(settings: settings);
      if (settings[idx].enabled && state.globalEnabled) {
        final t = _parseTime(settings[idx].time);
        await NotificationService.scheduleNotification(
          id: habitId.hashCode,
          title: settings[idx].habitTitle,
          body: 'Time to complete your habit!',
          hour: t['hour']!,
          minute: t['minute']!,
        );
      } else {
        await NotificationService.cancelNotification(habitId.hashCode);
      }
      await _save();
    }
  }

  Future<void> setHabitTime(String habitId, String time) async {
    final settings = List<NotificationSetting>.from(state.settings);
    final idx = settings.indexWhere((s) => s.habitId == habitId);
    if (idx != -1) {
      settings[idx].time = time;
      state = state.copyWith(settings: settings);
      if (settings[idx].enabled && state.globalEnabled) {
        final t = _parseTime(time);
        await NotificationService.scheduleNotification(
          id: habitId.hashCode,
          title: settings[idx].habitTitle,
          body: 'Time to complete your habit!',
          hour: t['hour']!,
          minute: t['minute']!,
        );
      }
      await _save();
    }
  }

  Future<void> reload() => _load();
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        () => NotificationNotifier());