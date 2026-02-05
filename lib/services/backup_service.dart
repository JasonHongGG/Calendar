import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

class CalendarBackup {
  CalendarBackup({required this.version, required this.exportedAt, required this.settings, required this.events});

  static const String schema = 'calendar_backup';
  static const int currentVersion = 1;

  final int version;
  final DateTime exportedAt;
  final Map<String, dynamic> settings;
  final List<Event> events;

  Map<String, dynamic> toMap() {
    return {'schema': schema, 'version': version, 'exportedAt': exportedAt.toIso8601String(), 'settings': settings, 'events': events.map((e) => e.toJson()).toList()};
  }

  String toJsonString({bool pretty = true}) {
    final map = toMap();
    return pretty ? const JsonEncoder.withIndent('  ').convert(map) : jsonEncode(map);
  }

  static CalendarBackup fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON root');
    }

    final schemaValue = decoded['schema'];
    if (schemaValue != schema) {
      throw const FormatException('Invalid backup schema');
    }

    final versionValue = decoded['version'];
    final version = versionValue is int ? versionValue : int.tryParse('$versionValue') ?? 0;
    if (version <= 0) {
      throw const FormatException('Invalid backup version');
    }

    final exportedAtRaw = decoded['exportedAt'];
    final exportedAt = exportedAtRaw is String ? DateTime.tryParse(exportedAtRaw) : null;

    final settingsRaw = decoded['settings'];
    final settings = settingsRaw is Map<String, dynamic> ? settingsRaw : <String, dynamic>{};

    final eventsRaw = decoded['events'];
    final eventsList = <Event>[];
    if (eventsRaw is List) {
      for (final item in eventsRaw) {
        if (item is Map) {
          eventsList.add(Event.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return CalendarBackup(version: version, exportedAt: exportedAt ?? DateTime.now(), settings: settings, events: eventsList);
  }
}

class BackupCodec {
  static Map<String, dynamic> settingsToJson(SettingsProvider settings) {
    return {'monthEventTitleSize': settings.monthEventTitleSize.name, 'eventColorTone': settings.eventColorTone.name, 'aiEnabled': settings.aiEnabled, 'aiBaseUrl': settings.aiBaseUrl};
  }

  static void applySettingsFromJson(SettingsProvider settings, Map<String, dynamic> json) {
    final sizeRaw = json['monthEventTitleSize'];
    final sizeName = sizeRaw is String ? sizeRaw : null;

    MonthEventTitleSize? parsedSize;
    if (sizeName != null) {
      for (final value in MonthEventTitleSize.values) {
        if (value.name == sizeName) {
          parsedSize = value;
          break;
        }
      }
    }

    final aiEnabledRaw = json['aiEnabled'];
    final bool? aiEnabled = aiEnabledRaw is bool ? aiEnabledRaw : null;

    final aiBaseUrlRaw = json['aiBaseUrl'];
    final String? aiBaseUrl = aiBaseUrlRaw is String ? aiBaseUrlRaw : null;

    final toneRaw = json['eventColorTone'];
    final toneName = toneRaw is String ? toneRaw : null;

    EventColorTone? parsedTone;
    if (toneName != null) {
      for (final value in EventColorTone.values) {
        if (value.name == toneName) {
          parsedTone = value;
          break;
        }
      }
    }

    settings.applyBackup(monthEventTitleSize: parsedSize, eventColorTone: parsedTone, aiEnabled: aiEnabled, aiBaseUrl: aiBaseUrl);
  }

  static List<Event> normalizeImportedEvents(List<Event> events) {
    final uuid = const Uuid();
    return events.map((e) {
      if (e.id.trim().isNotEmpty) return e;
      return e.copyWith(id: uuid.v4());
    }).toList();
  }
}
