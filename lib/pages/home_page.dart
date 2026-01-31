import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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

  final List<Widget> _pages = const [MonthViewPage(), SchedulePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 頁面內容 (使用 Positioned.fill 確保填滿)
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),

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
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.calendar_month_rounded,
                label: '月視圖',
              ),
              // 中間分隔線
              Container(width: 1, height: 24, color: AppColors.dividerLight),
              _buildNavItem(
                index: 1,
                icon: Icons.format_list_bulleted_rounded,
                label: '日程',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
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
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gradientStart.withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppColors.gradientStart
                    : AppColors.textTertiary,
              ),
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
