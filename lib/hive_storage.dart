import 'package:hive_flutter/hive_flutter.dart';
import 'habit_model.dart';
import 'user_model.dart';

// ─── Hive Adapters ────────────────────────────────────────────────────────────
// These remain for offline caching only. Supabase is the source-of-truth.

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

// ─── Storage Initialiser ─────────────────────────────────────────────────────

class HiveStorage {
  static const String habitBoxName = 'habitsBox_v2';
  static const String userBoxName = 'usersBox_v2';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    await Hive.openBox<HabitModel>(habitBoxName);
    await Hive.openBox<UserModel>(userBoxName);
  }

  static Box<HabitModel> get habitBox => Hive.box<HabitModel>(habitBoxName);
  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
}
