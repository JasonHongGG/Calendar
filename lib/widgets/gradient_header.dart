import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 日曆標題組件 (無漸層，簡約風格)
class CalendarHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSettings;
  final VoidCallback? onTitleTap;
  final VoidCallback? onTodayTap;

  const CalendarHeader({
    super.key,
    required this.title,
    this.onPrevious,
    this.onNext,
    this.onSettings,
    this.onTitleTap,
    this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左側導航區塊：< yyyy/mm >
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrevious,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTitleTap,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
              ),
            ],
          ),
          // 右側按鈕區塊
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onTodayTap != null) ...[
                _buildIconButton(
                  icon: Icons.calendar_today_outlined,
                  onTap: onTodayTap,
                ),
                const SizedBox(width: 4),
              ],
              _buildIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}
