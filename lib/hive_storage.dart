import 'package:hive_flutter/hive_flutter.dart';
import 'habit_model.dart';
import 'user_model.dart';

/// Hive Adapters for serialization/deserialization
class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final raw = reader.readMap();
    // Convert dynamic keys to String safely
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    return HabitModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer.writeMap(obj.toMap());
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final raw = reader.readMap();
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    return UserModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeMap(obj.toMap());
  }
}

/// Hive Storage Service - Primary storage for offline-first app
/// All data is persisted locally. Backup/restore to Google Drive is optional.
class HiveStorage {
  static const String habitBoxName = 'habitsBox_v2';
  static const String userBoxName = 'usersBox_v2';

  /// Initialize Hive and register all adapters
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    
    // Open boxes
    await Hive.openBox<HabitModel>(habitBoxName);
    await Hive.openBox<UserModel>(userBoxName);
  }

  /// Get habits box - all habits stored locally
  static Box<HabitModel> get habitBox => Hive.box<HabitModel>(habitBoxName);

  /// Get users box - user profiles stored locally
  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);

  /// Clear all local data (useful for testing or full reset)
  static Future<void> clearAll() async {
    await habitBox.clear();
    await userBox.clear();
  }

  /// Get total count of habits
  static int getHabitCount() => habitBox.length;

  /// Get total count of completions across all habits
  static int getTotalCompletions() {
    int total = 0;
    for (final habit in habitBox.values) {
      total += habit.completedDates.length;
    }
    return total;
  }
}
