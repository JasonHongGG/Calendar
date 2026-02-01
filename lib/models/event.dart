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

  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isAllDay = false,
    this.colorIndex = 0,
    this.location,
    this.description,
    this.reminderTime,
  });

  /// 檢查事件是否在指定日期
  bool isOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  /// 檢查是否為多日事件
  bool get isMultiDay {
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.isAfter(startOnly);
  }

  /// 計算事件持續天數
  int get durationDays {
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.difference(startOnly).inDays + 1;
  }

  /// 複製事件
  Event copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    int? colorIndex,
    String? location,
    String? description,
    DateTime? reminderTime,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      colorIndex: colorIndex ?? this.colorIndex,
      location: location ?? this.location,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
