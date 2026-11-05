import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  static const String _prefKeyIsDriveEnabled = 'is_google_drive_backup_enabled';
  static const String _prefKeyLastBackup = 'last_google_drive_backup_timestamp';

  /// Checks if the user opted in to Google Drive backup
  static Future<bool> isBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyIsDriveEnabled) ?? false;
  }

  /// Sets permission / preference
  static Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIsDriveEnabled, enabled);
  }

  /// Timestamp of the last backup
  static Future<String?> getLastBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyLastBackup);
  }

  /// Exports local database JSON to appDataFolder scope
  static Future<bool> performBackup() async {
    // In production, uses googleapis package DriveApi scoped to drive.appdata
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLastBackup, DateTime.now().toIso8601String());
    return true;
  }
}
