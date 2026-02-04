import 'package:hive/hive.dart';

class BackupMetaStore {
  static const String _boxName = 'backup_meta';
  static const String _keyLastDeleteBackupJson = 'last_delete_backup_json';

  Future<Box<dynamic>> _openBox() {
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<void> saveLastDeleteBackupJson(String jsonString) async {
    final box = await _openBox();
    await box.put(_keyLastDeleteBackupJson, jsonString);
  }

  Future<String?> getLastDeleteBackupJson() async {
    final box = await _openBox();
    final value = box.get(_keyLastDeleteBackupJson);
    return value is String ? value : null;
  }

  Future<void> clearLastDeleteBackup() async {
    final box = await _openBox();
    await box.delete(_keyLastDeleteBackupJson);
  }
}
