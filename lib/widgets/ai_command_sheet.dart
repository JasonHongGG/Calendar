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

enum _AiStepStatus { pending, running, done, error }

class _AiStep {
  _AiStep(this.title, this.status);

  final String title;
  _AiStepStatus status;
}

class _AiCommandSheetState extends State<AiCommandSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;
  final List<_AiStep> _steps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [_buildProgressList(), _buildInputRow()]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressList() {
    if (_steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final step = _steps[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStepStatusIcon(step.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(color: step.status == _AiStepStatus.done ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, fontWeight: step.status == _AiStepStatus.running ? FontWeight.w600 : FontWeight.w500),
                  ),
                ),
                if (step.status == _AiStepStatus.done)
                  Text(
                    '完成',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepStatusIcon(_AiStepStatus status) {
    switch (status) {
      case _AiStepStatus.running:
        return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gradientStart));
      case _AiStepStatus.done:
        return const Icon(Icons.check_circle_rounded, color: AppColors.gradientStart, size: 16);
      case _AiStepStatus.error:
        return const Icon(Icons.error_rounded, color: Colors.redAccent, size: 16);
      case _AiStepStatus.pending:
        return Icon(Icons.circle_outlined, color: AppColors.textTertiary.withValues(alpha: 0.6), size: 14);
    }
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: '輸入指令：新增、刪除、修改、提醒…', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 10),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final child = _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18, color: Colors.white);

    return IgnorePointer(
      ignoring: _sending,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _sending ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submit,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Center(child: child),
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
    _resetSteps();
    final understandingIndex = _addStep('理解需求中', _AiStepStatus.running);

    try {
      final service = AiCommandService(baseUrl: widget.baseUrl);
      var response = await service.sendCommand(requestText);

      _updateStep(understandingIndex, _AiStepStatus.done);
      final toolCheckIndex = _addStep('檢查是否需要工具', _AiStepStatus.running);

      debugPrint('[AI] initial actions: ${response.actions.map((a) => a.type).toList()}');

      final toolActions = response.actions.where((action) => action.type == 'tool_request').toList();
      if (toolActions.isEmpty) {
        _updateStep(toolCheckIndex, _AiStepStatus.done);
        _addStep('無需使用工具', _AiStepStatus.done);
      } else {
        _updateStep(toolCheckIndex, _AiStepStatus.done);
      }

      final toolResults = await _runToolRequests(response.actions);
      if (toolResults.isNotEmpty) {
        final mergeIndex = _addStep('整合工具結果', _AiStepStatus.running);
        debugPrint('[AI] tool results: ${toolResults.map((r) => r['tool']).toList()}');
        debugPrint('[AI] tool results payload: $toolResults');
        response = await service.sendCommand(requestText, toolResults: toolResults);
        _updateStep(mergeIndex, _AiStepStatus.done);
      }

      debugPrint('[AI] final actions: ${response.actions.map((a) => a.type).toList()}');
      debugPrint('[AI] final message: ${response.message ?? ''}');

      final applyIndex = _addStep('套用動作', _AiStepStatus.running);
      await _applyAiActions(response.actions, response.message);
      _updateStep(applyIndex, _AiStepStatus.done);
      _addStep('完成', _AiStepStatus.done);
      _controller.clear();
      if (mounted) {
        _focusNode.requestFocus();
      }
    } catch (error) {
      _addStep('執行失敗', _AiStepStatus.error);
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
      final stepIndex = _addStep('使用工具：$tool', _AiStepStatus.running);

      switch (tool) {
        case 'list_events':
          results.add({'tool': tool, 'args': args, 'result': _listEvents(provider, args)});
          break;
        case 'search_events':
          results.add({'tool': tool, 'args': args, 'result': _searchEvents(provider, args)});
          break;
      }

      _updateStep(stepIndex, _AiStepStatus.done);
    }

    return results;
  }

  void _resetSteps() {
    if (!mounted) return;
    setState(_steps.clear);
  }

  int _addStep(String title, _AiStepStatus status) {
    if (!mounted) return -1;
    setState(() {
      _steps.add(_AiStep(title, status));
    });
    return _steps.length - 1;
  }

  void _updateStep(int index, _AiStepStatus status) {
    if (!mounted || index < 0 || index >= _steps.length) return;
    setState(() {
      _steps[index].status = status;
    });
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
          final startDate = DateTime.parse(action.payload['startDate'] as String? ?? DateTime.now().toIso8601String());
          var endDate = DateTime.parse(action.payload['endDate'] as String? ?? DateTime.now().toIso8601String());
          final isAllDay = action.payload['isAllDay'] as bool? ?? true;
          if (isAllDay && _shouldNormalizeAllDayEndDate(startDate, endDate)) {
            endDate = startDate;
          }
          await provider.addEvent(title: action.payload['title'] as String? ?? '未命名事件', startDate: startDate, endDate: endDate, isAllDay: isAllDay, colorIndex: action.payload['colorIndex'] as int? ?? 0, description: action.payload['description'] as String?, reminderTime: reminderEnabled ? reminderTime : null);
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
          final updated = existing.copyWith(title: action.payload['title'] as String? ?? existing.title, startDate: resolvedStartDate, endDate: resolvedEndDate, isAllDay: resolvedIsAllDay, colorIndex: action.payload['colorIndex'] as int? ?? existing.colorIndex, description: action.payload['description'] as String? ?? existing.description, reminderTime: resolvedReminderTime);
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
