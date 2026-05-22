import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'habit_model.dart';
import 'user_model.dart';
import 'hive_storage.dart';
import 'notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Drive Backup Service
/// Handles backup and restore of habit data to Google Drive
class GoogleDriveBackupService {
  static const String _backupFolderName = 'HabitFlow Backups';
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _backupAppName = 'HabitFlow';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveScope],
  );

  GoogleSignInAccount? _currentAccount;
  drive.DriveApi? _driveApi;

  /// Check if user is signed in
  bool get isSignedIn => _currentAccount != null;

  /// Get current signed-in user email
  String? get userEmail => _currentAccount?.email;

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastBackupKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      print('Error getting last backup time: $e');
    }
    return null;
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentAccount = await _googleSignIn.signIn();
      if (_currentAccount != null) {
        final client = await _googleSignIn.authenticatedClient();
        if (client != null) {
          _driveApi = drive.DriveApi(client);
          return true;
        }
      }
    } catch (e) {
      print('Google Sign-In error: $e');
    }
    return false;
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentAccount = null;
      _driveApi = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Create or get backup folder on Google Drive
  Future<String?> _getOrCreateBackupFolder() async {
    if (_driveApi == null) return null;

    try {
      // Search for existing backup folder
      final result = await _driveApi!.files.list(
        q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        pageSize: 10,
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      // Create new folder if not found
      final folder = drive.File();
      folder.name = _backupFolderName;
      folder.mimeType = 'application/vnd.google-apps.folder';

      final created = await _driveApi!.files.create(folder);
      return created.id;
    } catch (e) {
      print('Error managing backup folder: $e');
    }
    return null;
  }

  /// Create backup data JSON
  Map<String, dynamic> _createBackupData() {
    final habits = HiveStorage.habitBox.values.toList();
    final userBox = HiveStorage.userBox;
    UserModel? user;
    if (userBox.isNotEmpty) {
      user = userBox.values.first;
    }

    return {
      'version': '1.0',
      'appName': _backupAppName,
      'createdAt': DateTime.now().toIso8601String(),
      'user': user?.toMap() ?? {},
      'habits': habits.map((h) => h.toMap()).toList(),
      'metadata': {
        'totalHabits': habits.length,
        'totalCompletions': habits.fold<int>(
          0,
          (sum, h) => sum + h.completedDates.length,
        ),
      },
    };
  }

  /// Backup data to Google Drive
  Future<bool> backupToGoogleDrive({
    required Function(String message) onProgress,
  }) async {
    try {
      if (_driveApi == null) {
        onProgress('Not signed in');
        return false;
      }

      onProgress('Preparing backup data...');
      final backupData = _createBackupData();
      final backupJson = jsonEncode(backupData);

      onProgress('Creating backup folder...');
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) {
        onProgress('Failed to create backup folder');
        return false;
      }

      onProgress('Uploading backup...');
      final timestamp = DateTime.now();
      final filename =
          'HabitFlow_Backup_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.json';

      final file = drive.File();
      file.name = filename;
      file.parents = [folderId];
      file.description = 'HabitFlow backup created on $timestamp';

      // Build a Media object from bytes (googleapis v16 API)
      final bytes = utf8.encode(backupJson);
      await _driveApi!.files.create(
        file,
        uploadMedia: drive.Media(Stream.fromIterable([bytes]), bytes.length),
      );

      onProgress('Backup completed successfully!');

      // Save last backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, timestamp.toIso8601String());

      return true;
    } catch (e) {
      onProgress('Backup failed: $e');
      print('Backup error: $e');
      return false;
    }
  }

  /// Get list of available backups from Google Drive
  Future<List<DriveBackupFile>> getAvailableBackups() async {
    try {
      if (_driveApi == null) return [];

      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return [];

      final result = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed=false",
        spaces: 'drive',
        pageSize: 50,
        orderBy: 'createdTime desc',
      );

      final backups = <DriveBackupFile>[];
      if (result.files != null) {
        for (final f in result.files!) {
          backups.add(
            DriveBackupFile(
              id: f.id ?? '',
              name: f.name ?? '',
              createdTime: f.createdTime ?? DateTime.now(),
              size: int.tryParse(f.size ?? '0') ?? 0,
            ),
          );
        }
      }
      return backups;
    } catch (e) {
      print('Error fetching backups: $e');
      return [];
    }
  }

  /// Restore data from Google Drive backup
  Future<bool> restoreFromGoogleDrive({
    required String fileId,
    required Function(String message) onProgress,
  }) async {
    try {
      if (_driveApi == null) {
        onProgress('Not signed in');
        return false;
      }

      onProgress('Downloading backup...');
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      onProgress('Processing backup data...');
      // Collect all byte chunks from the stream
      final byteChunks = await media.stream.toList();
      final allBytes = byteChunks.expand((e) => e).toList();
      final backupJson = utf8.decode(allBytes);
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Validate backup structure
      if (!backupData.containsKey('habits')) {
        onProgress('Invalid backup file format');
        return false;
      }

      onProgress('Restoring habits...');
      final habitBox = HiveStorage.habitBox;
      await habitBox.clear();

      if (backupData['habits'] is List) {
        for (final habitData in backupData['habits'] as List) {
          try {
            final habit = HabitModel.fromMap(habitData);
            await habitBox.put(habit.id, habit);
          } catch (e) {
            print('Error restoring habit: $e');
          }
        }
      }

      onProgress('Restoring user profile...');
      if (backupData['user'] is Map) {
        try {
          final userData = backupData['user'] as Map<String, dynamic>;
          final user = UserModel.fromMap(userData);
          final userBox = HiveStorage.userBox;
          await userBox.put(user.id, user);
        } catch (e) {
          print('Error restoring user: $e');
        }
      }

      onProgress('Restore completed successfully!');
      return true;
    } catch (e) {
      onProgress('Restore failed: $e');
      print('Restore error: $e');
      return false;
    }
  }

  /// Delete a backup from Google Drive
  Future<bool> deleteBackup(String fileId) async {
    try {
      if (_driveApi == null) return false;
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }
}

/// Represents a backup file on Google Drive
class DriveBackupFile {
  final String id;
  final String name;
  final DateTime createdTime;
  final int size;

  DriveBackupFile({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
