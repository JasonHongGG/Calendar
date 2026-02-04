import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_command_service.dart';
import '../theme/app_colors.dart';
import 'top_notification.dart';

class AiCommandSheet extends StatefulWidget {
  const AiCommandSheet({super.key, required this.baseUrl, this.onJumpToMonth});

  final String baseUrl;
  final VoidCallback? onJumpToMonth;

  static Future<void> open(BuildContext context, {VoidCallback? onJumpToMonth}) {
    final baseUrl = context.read<SettingsProvider>().aiBaseUrl;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiCommandSheet(baseUrl: baseUrl, onJumpToMonth: onJumpToMonth),
    );
  }

  @override
  State<AiCommandSheet> createState() => _AiCommandSheetState();
}

class _AiCommandSheetState extends State<AiCommandSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(hintText: '輸入指令：新增、刪除、修改、提醒…', border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gradientStart,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final localDate = _formatDate(DateTime.now());
    final requestText = '$text\nLOCAL_DATE: $localDate';

    debugPrint('[AI] input: $text');
    debugPrint('[AI] local date: $localDate');

    setState(() {
      _sending = true;
    });

    try {
      final service = AiCommandService(baseUrl: widget.baseUrl);
      var response = await service.sendCommand(requestText);

      debugPrint('[AI] initial actions: ${response.actions.map((a) => a.type).toList()}');

      final toolResults = await _runToolRequests(response.actions);
      if (toolResults.isNotEmpty) {
        debugPrint('[AI] tool results: ${toolResults.map((r) => r['tool']).toList()}');
        debugPrint('[AI] tool results payload: $toolResults');
        response = await service.sendCommand(requestText, toolResults: toolResults);
      }

      debugPrint('[AI] final actions: ${response.actions.map((a) => a.type).toList()}');
      debugPrint('[AI] final message: ${response.message ?? ''}');

      await _applyAiActions(response.actions, response.message);
      _controller.clear();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      NotificationOverlay.show(context: context, message: 'AI 指令失敗：$error', type: NotificationType.error);
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _runToolRequests(List<AiAction> actions) async {
    final provider = context.read<EventProvider>();
    final toolActions = actions.where((action) => action.type == 'tool_request').toList();
    if (toolActions.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    for (final action in toolActions) {
      final payload = action.payload;
      final tool = payload['tool'] as String?;
      final args = (payload['args'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (tool == null) continue;

      switch (tool) {
        case 'list_events':
          results.add({'tool': tool, 'args': args, 'result': _listEvents(provider, args)});
          break;
        case 'search_events':
          results.add({'tool': tool, 'args': args, 'result': _searchEvents(provider, args)});
          break;
      }
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
    final query = (args['query'] as String? ?? '').toLowerCase();
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

  List<Event> _filterEvents(List<Event> events, DateTime? start, DateTime? end) {
    if (start == null || end == null) return events;
    return events.where((event) {
      final eventStart = event.startDate;
      final eventEnd = event.endDate;
      return eventStart.isBefore(end) && eventEnd.isAfter(start);
    }).toList();
  }

  Map<String, dynamic> _eventToToolJson(Event event) {
    return {'id': event.id, 'title': event.title, 'startDate': event.startDate.toIso8601String(), 'endDate': event.endDate.toIso8601String(), 'isAllDay': event.isAllDay, 'colorIndex': event.colorIndex, 'description': event.description, 'reminderTime': event.reminderTime?.toIso8601String()};
  }

  Future<void> _applyAiActions(List<AiAction> actions, String? message) async {
    final provider = context.read<EventProvider>();

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
            widget.onJumpToMonth?.call();
          }
          break;
        case 'tool_request':
          break;
        case 'add_event':
          final reminderEnabled = action.payload['reminderEnabled'] as bool? ?? false;
          final reminderTime = action.payload['reminderTime'] != null ? DateTime.parse(action.payload['reminderTime'] as String) : null;
          await provider.addEvent(
            title: action.payload['title'] as String? ?? '未命名事件',
            startDate: DateTime.parse(action.payload['startDate'] as String? ?? DateTime.now().toIso8601String()),
            endDate: DateTime.parse(action.payload['endDate'] as String? ?? DateTime.now().toIso8601String()),
            isAllDay: action.payload['isAllDay'] as bool? ?? true,
            colorIndex: action.payload['colorIndex'] as int? ?? 0,
            description: action.payload['description'] as String?,
            reminderTime: reminderEnabled ? reminderTime : null,
          );
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
          final updated = existing.copyWith(
            title: action.payload['title'] as String? ?? existing.title,
            startDate: action.payload['startDate'] != null ? DateTime.parse(action.payload['startDate'] as String) : existing.startDate,
            endDate: action.payload['endDate'] != null ? DateTime.parse(action.payload['endDate'] as String) : existing.endDate,
            isAllDay: action.payload['isAllDay'] as bool? ?? existing.isAllDay,
            colorIndex: action.payload['colorIndex'] as int? ?? existing.colorIndex,
            description: action.payload['description'] as String? ?? existing.description,
            reminderTime: resolvedReminderTime,
          );
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

    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      NotificationOverlay.show(context: context, message: message, type: NotificationType.success);
    } else {
      NotificationOverlay.show(context: context, message: 'AI 指令已處理', type: NotificationType.success);
    }
  }
}
