import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/calendar_layout.dart';
import '../widgets/month_calendar.dart';

class MonthWidgetSnapshot extends StatelessWidget {
  final DateTime month;

  const MonthWidgetSnapshot({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
      child: Container(
        width: double.infinity,
        height: CalendarLayout.monthContainerHeight,
        color: Colors.white,
        child: Column(
          children: [
            _buildWeekdayHeader(),
            const Divider(height: 1),
            Expanded(child: MonthCalendar(currentMonth: month, selectedDate: null, onDateSelected: null, onDateLongPress: null, onEventTap: null)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSmall),
      child: Row(
        children: ['日', '一', '二', '三', '四', '五', '六'].map((label) {
          final isSunday = label == '日';
          final isSaturday = label == '六';
          Color textColor;
          if (isSunday) {
            textColor = AppColors.textSunday;
          } else if (isSaturday) {
            textColor = AppColors.textSaturday;
          } else {
            textColor = AppColors.textSecondary;
          }

          return Expanded(
            child: Center(
              child: Text(label, style: AppTextStyles.weekdayLabel.copyWith(color: textColor)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
