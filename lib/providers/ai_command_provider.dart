import 'package:flutter/material.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../services/ai_command_service.dart';

enum AiStepStatus { pending, running, done, error }

class AiStep {
  AiStep(this.title, this.status);

  final String title;
  AiStepStatus status;
}

class AiCommandProvider extends ChangeNotifier {
  final List<AiStep> _steps = [];
  bool _sending = false;
  String _draftText = '';

  List<AiStep> get steps => List.unmodifiable(_steps);
  bool get sending => _sending;
  String get draftText => _draftText;

  void setDraftText(String value) {
    if (_draftText == value) return;
    _draftText = value;
    notifyListeners();
  }

  Future<void> submit({required String text, required String baseUrl, required EventProvider eventProvider, VoidCallback? onJumpToMonth}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    _sending = true;
    _resetSteps();
    final understandingIndex = _addStep('理解需求中', AiStepStatus.running);

    final localDate = _formatDate(DateTime.now());
    final requestText = '$trimmed\nLOCAL_DATE: $localDate';

    try {
      final service = AiCommandService(baseUrl: baseUrl);
      var response = await service.sendCommand(requestText);

      _updateStep(understandingIndex, AiStepStatus.done);
      final toolCheckIndex = _addStep('檢查是否需要工具', AiStepStatus.running);

      final toolActions = response.actions.where((action) => action.type == 'tool_request').toList();
      if (toolActions.isEmpty) {
        _updateStep(toolCheckIndex, AiStepStatus.done);
        _addStep('無需使用工具', AiStepStatus.done);
      } else {
        _updateStep(toolCheckIndex, AiStepStatus.done);
      }

      final toolResults = await _runToolRequests(response.actions, eventProvider);
      if (toolResults.isNotEmpty) {
        final mergeIndex = _addStep('整合工具結果', AiStepStatus.running);
        response = await service.sendCommand(requestText, toolResults: toolResults);
        _updateStep(mergeIndex, AiStepStatus.done);
      }

      final applyIndex = _addStep('套用動作', AiStepStatus.running);
      await _applyAiActions(response.actions, response.message, eventProvider, onJumpToMonth);
      _updateStep(applyIndex, AiStepStatus.done);

      if (response.message != null && response.message!.trim().isNotEmpty) {
        _addStep('完成：${response.message}', AiStepStatus.done);
      } else {
        _addStep('完成', AiStepStatus.done);
      }
    } catch (error) {
      _addStep('執行失敗：$error', AiStepStatus.error);
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _runToolRequests(List<AiAction> actions, EventProvider eventProvider) async {
    final toolActions = actions.where((action) => action.type == 'tool_request').toList();
    if (toolActions.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    for (final action in toolActions) {
      final payload = action.payload;
      final tool = payload['tool'] as String?;
      final args = (payload['args'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (tool == null) continue;

      final stepIndex = _addStep('使用工具：$tool', AiStepStatus.running);

      switch (tool) {
        case 'list_events':
          results.add({'tool': tool, 'args': args, 'result': _listEvents(eventProvider, args)});
          break;
        case 'search_events':
          results.add({'tool': tool, 'args': args, 'result': _searchEvents(eventProvider, args)});
          break;
      }

      _updateStep(stepIndex, AiStepStatus.done);
    }

    return results;
  }

  List<Map<String, dynamic>> _listEvents(EventProvider provider, Map<String, dynamic> args) {
    DateTime? start;
    DateTime? end;
    final dateArg = args['date'] as String?;
    if (dateArg != null && dateArg.trim().isNotEmpty) {
      start = DateTime.parse(dateArg);
      end = start.add(const Duration(days: 1));
    } else if (args['rangeStart'] is String && args['rangeEnd'] is String) {
      start = DateTime.parse(args['rangeStart'] as String);
      end = DateTime.parse(args['rangeEnd'] as String).add(const Duration(days: 1));
    }

    return _filterEvents(provider.events, start, end).map(_eventToToolJson).toList();
  }

  List<Map<String, dynamic>> _searchEvents(EventProvider provider, Map<String, dynamic> args) {
    final queryValue = (args['query'] as String?) ?? (args['title'] as String?) ?? (args['keyword'] as String?) ?? (args['name'] as String?) ?? '';
    final query = queryValue.toLowerCase();
    DateTime? start;
    DateTime? end;
    final dateArg = args['date'] as String?;
    if (dateArg != null && dateArg.trim().isNotEmpty) {
      start = DateTime.parse(dateArg);
      end = start.add(const Duration(days: 1));
    } else if (args['rangeStart'] is String && args['rangeEnd'] is String) {
      start = DateTime.parse(args['rangeStart'] as String);
      end = DateTime.parse(args['rangeEnd'] as String).add(const Duration(days: 1));
    }

    return _filterEvents(provider.events, start, end).where((event) => event.title.toLowerCase().contains(query) || (event.description ?? '').toLowerCase().contains(query)).map(_eventToToolJson).toList();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _shouldNormalizeAllDayEndDate(DateTime startDate, DateTime endDate) {
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    final isMidnight = endDate.hour == 0 && endDate.minute == 0 && endDate.second == 0 && endDate.millisecond == 0 && endDate.microsecond == 0;
    return isMidnight && endOnly.difference(startOnly).inDays == 1;
  }

  List<Event> _filterEvents(List<Event> events, DateTime? start, DateTime? end) {
    if (start == null || end == null) return events;
    return events.where((event) {
      final eventStart = event.startDate;
      final eventEnd = event.endDate;
      return eventStart.isBefore(end) && eventEnd.isAfter(start);
    }).toList();
  }

  Map<String, dynamic> _eventToToolJson(Event event) {
    return {'id': event.id, 'title': event.title, 'startDate': event.startDate.toIso8601String(), 'endDate': event.endDate.toIso8601String(), 'isAllDay': event.isAllDay, 'colorKey': event.colorKey, 'description': event.description, 'reminderTime': event.reminderTime?.toIso8601String()};
  }

  Future<void> _applyAiActions(List<AiAction> actions, String? message, EventProvider provider, VoidCallback? onJumpToMonth) async {
    Event? findEventById(String id) {
      for (final event in provider.events) {
        if (event.id == id) return event;
      }
      return null;
    }

    for (final action in actions) {
      switch (action.type) {
        case 'find_event':
          final payload = action.payload;
          DateTime? targetDate;
          if (payload['id'] is String) {
            final event = findEventById(payload['id'] as String);
            targetDate = event?.startDate;
          }
          if (targetDate == null && payload['startDate'] is String) {
            targetDate = DateTime.parse(payload['startDate'] as String);
          }
          if (targetDate == null && payload['date'] is String) {
            targetDate = DateTime.parse(payload['date'] as String);
          }

          if (targetDate != null) {
            provider.setCurrentMonth(DateTime(targetDate.year, targetDate.month));
            provider.setSelectedDate(targetDate);
            onJumpToMonth?.call();
          }
          break;
        case 'tool_request':
          break;
        case 'add_event':
          final reminderEnabled = action.payload['reminderEnabled'] as bool? ?? false;
          final reminderTime = action.payload['reminderTime'] != null ? DateTime.parse(action.payload['reminderTime'] as String) : null;
          final startDate = DateTime.parse(action.payload['startDate'] as String? ?? DateTime.now().toIso8601String());
          var endDate = DateTime.parse(action.payload['endDate'] as String? ?? DateTime.now().toIso8601String());
          final isAllDay = action.payload['isAllDay'] as bool? ?? true;
          if (isAllDay && _shouldNormalizeAllDayEndDate(startDate, endDate)) {
            endDate = startDate;
          }
          final colorKeyRaw = action.payload['colorKey'];
          final colorKey = colorKeyRaw is String && colorKeyRaw.isNotEmpty ? colorKeyRaw : 'red';
          await provider.addEvent(title: action.payload['title'] as String? ?? '未命名事件', startDate: startDate, endDate: endDate, isAllDay: isAllDay, colorKey: colorKey, description: action.payload['description'] as String?, reminderTime: reminderEnabled ? reminderTime : null);
          break;
        case 'delete_event':
          final id = action.payload['id'] as String?;
          if (id != null) {
            await provider.deleteEvent(id);
          }
          break;
        case 'update_event':
          final id = action.payload['id'] as String?;
          if (id == null) break;
          final existing = findEventById(id);
          if (existing == null) break;
          final reminderEnabled = action.payload['reminderEnabled'] as bool?;
          final reminderTime = action.payload['reminderTime'] != null ? DateTime.parse(action.payload['reminderTime'] as String) : null;
          final resolvedReminderTime = reminderEnabled == null ? (action.payload['reminderTime'] != null ? reminderTime : existing.reminderTime) : (reminderEnabled ? (reminderTime ?? existing.reminderTime) : null);
          final resolvedStartDate = action.payload['startDate'] != null ? DateTime.parse(action.payload['startDate'] as String) : existing.startDate;
          var resolvedEndDate = action.payload['endDate'] != null ? DateTime.parse(action.payload['endDate'] as String) : existing.endDate;
          final resolvedIsAllDay = action.payload['isAllDay'] as bool? ?? existing.isAllDay;
          if (resolvedIsAllDay && _shouldNormalizeAllDayEndDate(resolvedStartDate, resolvedEndDate)) {
            resolvedEndDate = resolvedStartDate;
          }
          final colorKeyRaw = action.payload['colorKey'];
          final colorKey = colorKeyRaw is String && colorKeyRaw.isNotEmpty ? colorKeyRaw : existing.colorKey;
          final updated = existing.copyWith(title: action.payload['title'] as String? ?? existing.title, startDate: resolvedStartDate, endDate: resolvedEndDate, isAllDay: resolvedIsAllDay, colorKey: colorKey, description: action.payload['description'] as String? ?? existing.description, reminderTime: resolvedReminderTime);
          await provider.updateEvent(updated);
          break;
        case 'toggle_reminder':
          final id = action.payload['id'] as String?;
          if (id == null) break;
          final existing = findEventById(id);
          if (existing == null) break;
          final enabled = action.payload['enabled'] as bool? ?? false;
          final reminderTime = action.payload['reminderTime'] != null ? DateTime.parse(action.payload['reminderTime'] as String) : existing.reminderTime;
          final updated = existing.copyWith(reminderTime: enabled ? reminderTime : null);
          await provider.updateEvent(updated);
          break;
      }
    }
  }

  void _resetSteps() {
    _steps.clear();
    notifyListeners();
  }

  int _addStep(String title, AiStepStatus status) {
    _steps.add(AiStep(title, status));
    notifyListeners();
    return _steps.length - 1;
  }

  void _updateStep(int index, AiStepStatus status) {
    if (index < 0 || index >= _steps.length) return;
    _steps[index].status = status;
    notifyListeners();
  }
}
