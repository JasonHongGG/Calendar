import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  bool isAllDay;

  @HiveField(5)
  int colorIndex;

  @HiveField(6)
  String? location;

  @HiveField(7)
  String? description;

  @HiveField(8)
  DateTime? reminderTime;

  Event({required this.id, required this.title, required this.startDate, required this.endDate, this.isAllDay = false, this.colorIndex = 0, this.location, this.description, this.reminderTime});

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'startDate': startDate.toIso8601String(), 'endDate': endDate.toIso8601String(), 'isAllDay': isAllDay, 'colorIndex': colorIndex, 'location': location, 'description': description, 'reminderTime': reminderTime?.toIso8601String()};
  }

  static Event fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final startRaw = json['startDate'];
    final endRaw = json['endDate'];

    final id = idRaw is String ? idRaw : '';
    final title = titleRaw is String ? titleRaw : '';
    final startDate = startRaw is String ? DateTime.tryParse(startRaw) : null;
    final endDate = endRaw is String ? DateTime.tryParse(endRaw) : null;

    final isAllDayRaw = json['isAllDay'];
    final colorIndexRaw = json['colorIndex'];
    final locationRaw = json['location'];
    final descriptionRaw = json['description'];
    final reminderRaw = json['reminderTime'];

    return Event(id: id, title: title, startDate: startDate ?? DateTime.now(), endDate: endDate ?? (startDate ?? DateTime.now()), isAllDay: isAllDayRaw is bool ? isAllDayRaw : false, colorIndex: colorIndexRaw is int ? colorIndexRaw : int.tryParse('$colorIndexRaw') ?? 0, location: locationRaw is String ? locationRaw : null, description: descriptionRaw is String ? descriptionRaw : null, reminderTime: reminderRaw is String ? DateTime.tryParse(reminderRaw) : null);
  }

  /// 檢查事件是否在指定日期
  bool isOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = normalizedEndDate;
    final endOnly = DateTime(normalizedEnd.year, normalizedEnd.month, normalizedEnd.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// 檢查是否為多日事件
  bool get isMultiDay {
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = normalizedEndDate;
    final endOnly = DateTime(normalizedEnd.year, normalizedEnd.month, normalizedEnd.day);
    return endOnly.isAfter(startOnly);
  }

  /// 計算事件持續天數
  int get durationDays {
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = normalizedEndDate;
    final endOnly = DateTime(normalizedEnd.year, normalizedEnd.month, normalizedEnd.day);
    return endOnly.difference(startOnly).inDays + 1;
  }

  /// 全日事件在 00:00 結束且跨天時，將結束日視為前一天
  DateTime get normalizedEndDate {
    if (!isAllDay) return endDate;
    final isMidnight = endDate.hour == 0 && endDate.minute == 0 && endDate.second == 0 && endDate.millisecond == 0 && endDate.microsecond == 0;
    if (!isMidnight) return endDate;

    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    if (endOnly.isAfter(startOnly)) {
      return endOnly.subtract(const Duration(days: 1));
    }
    return endOnly;
  }

  /// 複製事件
  Event copyWith({String? id, String? title, DateTime? startDate, DateTime? endDate, bool? isAllDay, int? colorIndex, String? location, String? description, DateTime? reminderTime}) {
    return Event(id: id ?? this.id, title: title ?? this.title, startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate, isAllDay: isAllDay ?? this.isAllDay, colorIndex: colorIndex ?? this.colorIndex, location: location ?? this.location, description: description ?? this.description, reminderTime: reminderTime ?? this.reminderTime);
  }
}
