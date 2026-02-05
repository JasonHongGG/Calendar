import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../utils/date_utils.dart';
import '../services/notification_service.dart';

/// 事件狀態管理器
class EventProvider extends ChangeNotifier {
  static const String _boxName = 'events';

  Box<Event>? _eventsBox;
  List<Event> _events = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  int _eventsVersion = 0;

  final Uuid _uuid = const Uuid();

  List<Event> get events => _events;
  int get eventsVersion => _eventsVersion;
  DateTime get selectedDate => _selectedDate;
  DateTime get currentMonth => _currentMonth;

  /// 初始化 Hive 並載入事件
  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(EventAdapter());
    }

    _eventsBox = await Hive.openBox<Event>(_boxName);
    _loadEvents();
  }

  /// 從本地資料庫載入事件
  void _loadEvents() {
    _events = _eventsBox?.values.toList() ?? [];
    // 按開始日期排序
    _events.sort((a, b) => a.startDate.compareTo(b.startDate));
    _eventsVersion++;
    notifyListeners();
  }

  /// 設定選中的日期
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 設定當前顯示的月份
  void setCurrentMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  /// 切換到上一個月
  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    notifyListeners();
  }

  /// 切換到下一個月
  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    notifyListeners();
  }

  /// 回到今天
  void goToToday() {
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
    notifyListeners();
  }

  /// 新增事件
  Future<void> addEvent({required String title, required DateTime startDate, required DateTime endDate, bool isAllDay = false, required String colorKey, bool isCompleted = false, String? location, String? description, DateTime? reminderTime}) async {
    final nextOrder = _nextSortOrderForDate(startDate);
    final event = Event(id: _uuid.v4(), title: title, startDate: startDate, endDate: endDate, isAllDay: isAllDay, colorKey: colorKey, sortOrder: nextOrder, isCompleted: isCompleted, location: location, description: description, reminderTime: reminderTime);

    await _eventsBox?.put(event.id, event);

    if (reminderTime != null) {
      // Use hashCode as notification ID (simple way)
      // Note: UUID hashcode might not be unique enough for int32 limit, but acceptable for this scale
      await NotificationService().scheduleNotification(id: _notificationIdForEventId(event.id), title: '行事曆提醒: $title', body: CalendarDateUtils.formatEventTime(startDate, endDate, isAllDay), scheduledDate: reminderTime);
    }
    _loadEvents();
  }

  /// 更新事件
  Future<void> updateEvent(Event event) async {
    await _eventsBox?.put(event.id, event);

    // Cancel existing notification first (just in case)
    await NotificationService().cancelNotification(_notificationIdForEventId(event.id));

    if (event.reminderTime != null) {
      await NotificationService().scheduleNotification(id: _notificationIdForEventId(event.id), title: '行事曆提醒: ${event.title}', body: CalendarDateUtils.formatEventTime(event.startDate, event.endDate, event.isAllDay), scheduledDate: event.reminderTime!);
    }
    _loadEvents();
  }

  /// 刪除事件
  Future<void> deleteEvent(String eventId) async {
    // We need to know the ID hashcode to cancel, assuming string ID is available
    // In delete, we often have the object. If we only have ID, we need to be careful.
    // However, string.hashCode is deterministic.
    await NotificationService().cancelNotification(_notificationIdForEventId(eventId));

    await _eventsBox?.delete(eventId);
    _loadEvents();
  }

  /// 以匯入內容覆蓋所有事件（用於匯入備份）
  Future<void> replaceAllEvents(List<Event> events) async {
    if (_eventsBox == null) {
      throw StateError('Event box not initialized');
    }

    // Replace storage first
    await _eventsBox!.clear();
    for (final event in events) {
      await _eventsBox!.put(event.id, event);
    }

    // Reschedule notifications based on imported data
    await NotificationService().cancelAllNotifications();
    for (final event in events) {
      final reminderTime = event.reminderTime;
      if (reminderTime == null) continue;
      await NotificationService().scheduleNotification(id: _notificationIdForEventId(event.id), title: '行事曆提醒: ${event.title}', body: CalendarDateUtils.formatEventTime(event.startDate, event.endDate, event.isAllDay), scheduledDate: reminderTime);
    }

    _loadEvents();
  }

  /// 合併匯入事件：同 id 覆蓋更新，不存在則新增（不會刪除原有事件）
  Future<void> mergeEvents(List<Event> events) async {
    if (_eventsBox == null) {
      throw StateError('Event box not initialized');
    }

    for (final event in events) {
      await _eventsBox!.put(event.id, event);

      // Keep notifications in sync for this event
      await NotificationService().cancelNotification(_notificationIdForEventId(event.id));
      final reminderTime = event.reminderTime;
      if (reminderTime != null) {
        await NotificationService().scheduleNotification(id: _notificationIdForEventId(event.id), title: '行事曆提醒: ${event.title}', body: CalendarDateUtils.formatEventTime(event.startDate, event.endDate, event.isAllDay), scheduledDate: reminderTime);
      }
    }

    _loadEvents();
  }

  Future<void> clearAllEvents() {
    return replaceAllEvents([]);
  }

  /// 取得指定日期的事件
  List<Event> getEventsForDate(DateTime date) {
    final list = _events.where((event) => event.isOnDate(date)).toList();
    list.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.startDate.compareTo(b.startDate);
    });
    return list;
  }

  Future<void> updateEventOrderForDate(DateTime date, List<String> orderedIds) async {
    if (_eventsBox == null) return;

    final byId = {for (final event in _events) event.id: event};
    final idSet = orderedIds.toSet();
    final remaining = _events.where((event) => event.isOnDate(date) && !idSet.contains(event.id)).toList();

    var order = 0;
    for (final id in orderedIds) {
      final event = byId[id];
      if (event == null) continue;
      event.sortOrder = order;
      order += 1;
      await _eventsBox!.put(event.id, event);
    }

    for (final event in remaining) {
      event.sortOrder = order;
      order += 1;
      await _eventsBox!.put(event.id, event);
    }

    _loadEvents();
  }

  int _nextSortOrderForDate(DateTime date) {
    final list = _events.where((event) => event.isOnDate(date)).toList();
    if (list.isEmpty) return 0;
    final maxOrder = list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
    return maxOrder + 1;
  }

  int _notificationIdForEventId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  /// 取得指定月份的事件
  List<Event> getEventsForMonth(DateTime month) {
    final firstDay = CalendarDateUtils.getFirstDayOfMonth(month);
    final lastDay = CalendarDateUtils.getLastDayOfMonth(month);

    return _events.where((event) {
      final startOnly = CalendarDateUtils.dateOnly(event.startDate);
      final endOnly = CalendarDateUtils.dateOnly(event.normalizedEndDate);

      // 事件與月份有交集
      return !endOnly.isBefore(firstDay) && !startOnly.isAfter(lastDay);
    }).toList();
  }

  /// 取得今日事件
  List<Event> get todayEvents {
    return getEventsForDate(DateTime.now());
  }

  /// 取得選中日期的事件
  List<Event> get selectedDateEvents {
    return getEventsForDate(_selectedDate);
  }

  /// 檢查指定日期是否有事件
  bool hasEventsOnDate(DateTime date) {
    return _events.any((event) => event.isOnDate(date));
  }

  /// 取得指定日期的事件顏色（用於日曆上的小圓點）
  List<String> getEventColorsForDate(DateTime date) {
    final list = _events.where((event) => event.isOnDate(date)).toList();
    list.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.startDate.compareTo(b.startDate);
    });
    final seen = <String>{};
    final ordered = <String>[];
    for (final event in list) {
      if (seen.add(event.colorKey)) {
        ordered.add(event.colorKey);
      }
    }
    return ordered;
  }

  /// 取得即將到來的事件（從今天開始的 7 天內）
  List<MapEntry<DateTime, List<Event>>> getUpcomingEvents() {
    final today = CalendarDateUtils.dateOnly(DateTime.now());
    final endDate = today.add(const Duration(days: 7));

    final Map<DateTime, List<Event>> grouped = {};

    for (var date = today; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      final eventsOnDate = getEventsForDate(date);
      if (eventsOnDate.isNotEmpty) {
        grouped[date] = eventsOnDate;
      }
    }

    return grouped.entries.toList();
  }

  @override
  void dispose() {
    _eventsBox?.close();
    super.dispose();
  }
}
