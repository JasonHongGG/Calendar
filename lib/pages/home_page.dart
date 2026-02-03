import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../widgets/top_notification.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/ai_command_sheet.dart';
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

  List<Widget> get _pages => const [MonthViewPage(), WeeklyViewPage(), SchedulePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final aiEnabled = context.watch<SettingsProvider>().aiEnabled;

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
            children: [
              Expanded(
                child: _buildNavItem(index: 0, icon: Icons.calendar_month_rounded, label: '月視圖'),
              ),
              Expanded(
                child: _buildNavItem(index: 1, icon: Icons.date_range_rounded, label: '週視圖'),
              ),
              Expanded(
                child: _buildNavItem(index: 2, icon: Icons.format_list_bulleted_rounded, label: '日程'),
              ),
              Expanded(
                child: _buildActionItem(icon: Icons.mic_rounded, onTap: aiEnabled ? _openAiSheet : _showAiDisabled, enabled: aiEnabled),
              ),
              Expanded(
                child: _buildActionItem(icon: Icons.add_rounded, onTap: () => showAddEventSheet(context), emphasize: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiSheet() {
    AiCommandSheet.open(context);
  }

  void _showAiDisabled() {
    NotificationOverlay.show(context: context, message: '請先在設定中啟用 AI 指令', type: NotificationType.info);
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 70,
        color: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isSelected ? AppColors.gradientStart.withValues(alpha: 0.1) : Colors.transparent, shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: isSelected ? AppColors.gradientStart : AppColors.textTertiary),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required VoidCallback onTap, bool enabled = true, bool emphasize = false}) {
    final color = enabled ? AppColors.gradientStart : AppColors.textTertiary;
    final background = emphasize ? AppColors.gradientStart.withValues(alpha: 0.16) : color.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 70,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
