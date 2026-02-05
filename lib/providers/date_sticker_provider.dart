import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/sticker_options.dart';
import '../utils/date_utils.dart';

class DateStickerProvider extends ChangeNotifier {
  static const String _boxName = 'date_stickers';

  Box<String>? _box;
  int _version = 0;
  final Map<String, String?> _cache = {};

  int get version => _version;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _version++;
    notifyListeners();
  }

  String? getStickerKey(DateTime date) {
    final key = CalendarDateUtils.formatDateKey(date);
    if (_cache.containsKey(key)) return _cache[key];
    final value = _box?.get(key);
    _cache[key] = value;
    return value;
  }

  String? getStickerEmoji(DateTime date) {
    final key = getStickerKey(date);
    if (key == null || key.isEmpty) return null;
    return StickerOptions.stickers[key];
  }

  Future<void> setSticker(DateTime date, String? stickerKey) async {
    if (_box == null) return;
    final key = CalendarDateUtils.formatDateKey(date);
    final normalized = stickerKey != null && stickerKey.isNotEmpty ? stickerKey : null;

    _cache[key] = normalized;
    _version++;
    notifyListeners();

    if (normalized == null) {
      await _box!.delete(key);
    } else {
      await _box!.put(key, normalized);
    }
  }
}
