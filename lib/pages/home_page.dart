import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_command_service.dart';
import '../widgets/top_notification.dart';
import 'weekly_view_page.dart';
import 'month_view_page.dart';
import 'schedule_page.dart';

/// 主頁面（底部導航殼層）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final TextEditingController _aiController = TextEditingController();
  final FocusNode _aiFocusNode = FocusNode();
  bool _aiSending = false;

  List<Widget> get _pages => const [
    MonthViewPage(),
    WeeklyViewPage(), // 新增週視圖
    SchedulePage(),
  ];

  @override
  void dispose() {
    _aiController.dispose();
    _aiFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final aiEnabled = settings.aiEnabled;

    if (!aiEnabled && _aiFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _aiFocusNode.unfocus();
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // 頁面內容 (使用 Positioned.fill 確保填滿)
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),

          if (aiEnabled) Positioned(left: 24, right: 24, bottom: 20 + 70 + 12, child: _buildAiInputBar()),

          // 底部導航欄
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(color: AppColors.shadow.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(index: 0, icon: Icons.calendar_month_rounded, label: '月視圖'),
              Container(width: 1, height: 24, color: AppColors.dividerLight),
              _buildNavItem(
                index: 1,
                icon: Icons.date_range_rounded, // 週視圖圖示
                label: '週視圖',
              ),
              Container(width: 1, height: 24, color: AppColors.dividerLight),
              _buildNavItem(index: 2, icon: Icons.format_list_bulleted_rounded, label: '日程'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiController,
              focusNode: _aiFocusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitAiCommand(),
              decoration: const InputDecoration(hintText: '輸入指令：新增、刪除、修改、提醒…', border: InputBorder.none),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _aiSending ? null : _submitAiCommand,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: _aiSending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAiCommand() async {
    final text = _aiController.text.trim();
    if (text.isEmpty || _aiSending) return;

    setState(() {
      _aiSending = true;
    });

    try {
      final settings = context.read<SettingsProvider>();
      final service = AiCommandService(baseUrl: settings.aiBaseUrl);
      final response = await service.sendCommand(text);
      await _applyAiActions(response.actions, response.message);
      _aiController.clear();
    } catch (error) {
      if (!mounted) return;
      NotificationOverlay.show(context: context, message: 'AI 指令失敗：$error', type: NotificationType.error);
    } finally {
      if (mounted) {
        setState(() {
          _aiSending = false;
        });
      }
    }
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

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.transparent, // 擴大點擊區域
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? AppColors.gradientStart.withValues(alpha: 0.1) : Colors.transparent, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: isSelected ? AppColors.gradientStart : AppColors.textTertiary),
            ),
            // 您可以選擇是否要保留文字，或者只顯示圖示
            // 如果要更極簡，可以移除下面的 Text
            // AnimatedOpacity(
            //   duration: const Duration(milliseconds: 200),
            //   opacity: isSelected ? 1.0 : 0.0,
            //   child: isSelected
            //       ? Text(label, style: TextStyle(fontSize: 10, color: AppColors.gradientStart))
            //       : const SizedBox(height: 10),
            // ),
          ],
        ),
      ),
    );
  }
}
