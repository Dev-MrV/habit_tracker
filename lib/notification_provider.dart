import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _prefKeyGlobalEnabled = 'notifications_global_enabled';
  static const String _prefKeySettings = 'notifications_settings';

  @override
  NotificationState build() {
    Future.microtask(_load);
    return NotificationState();
  }

  /// Parse time string like "Morning (7:00 AM)" to hour/minute
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

  /// Load notification preferences from SharedPreferences
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final globalEnabled = prefs.getBool(_prefKeyGlobalEnabled) ?? true;
      
      final settingsJson = prefs.getString(_prefKeySettings);
      List<NotificationSetting> settings = [];
      
      if (settingsJson != null) {
        final list = jsonDecode(settingsJson) as List<dynamic>;
        settings = list
            .map((e) => NotificationSetting.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      
      state = NotificationState(globalEnabled: globalEnabled, settings: settings);
      await _rescheduleAll();
    } catch (e) {
      print('Failed to load notifications: $e');
    }
  }

  /// Save notification preferences to SharedPreferences
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyGlobalEnabled, state.globalEnabled);
      
      final settingsJson = jsonEncode(
        state.settings.map((s) => s.toMap()).toList()
      );
      await prefs.setString(_prefKeySettings, settingsJson);
    } catch (e) {
      print('Failed to save notifications: $e');
    }
  }

  /// Reschedule all notifications
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

  /// Sync notification settings with habits
  void syncWithHabits(List<HabitModel> habits) {
    var settings = List<NotificationSetting>.from(state.settings);
    
    // Add new habits
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
    
    // Remove deleted habits
    settings.removeWhere((s) => !habits.any((h) => h.id == s.habitId));
    
    state = state.copyWith(settings: settings);
    _save();
  }

  /// Toggle global notifications
  Future<void> toggleGlobal() async {
    state = state.copyWith(globalEnabled: !state.globalEnabled);
    
    if (!state.globalEnabled) {
      // Cancel all notifications
      for (var s in state.settings) {
        await NotificationService.cancelNotification(s.habitId.hashCode);
      }
    } else {
      // Reschedule all
      await _rescheduleAll();
    }
    
    await _save();
  }

  /// Toggle notification for a specific habit
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

  /// Set notification time for a habit
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

  /// Reload notification preferences
  Future<void> reload() => _load();
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        () => NotificationNotifier());