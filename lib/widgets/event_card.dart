import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';

/// 事件卡片組件
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventCard({super.key, required this.event, this.onTap, this.onDelete});

  Color get _color =>
      AppColors.eventColors[event.colorIndex % AppColors.eventColors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0), // 外距由父層控制或設為 0
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // 1. 顏色指示 (圓點)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 2. 標題與地點
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // 3. 刪除按鈕
                if (onDelete != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textTertiary.withValues(alpha: 0.4),
                        size: 22,
                      ),
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        hoverColor: Colors.red.withValues(alpha: 0.1),
                        highlightColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 小型事件卡片（用於今日預覽）
class EventCardCompact extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCardCompact({super.key, required this.event, this.onTap});

  Color get _color =>
      AppColors.eventColors[event.colorIndex % AppColors.eventColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 顏色圓點
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            // 標題
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 時間
            Text(
              CalendarDateUtils.formatTimeRange(
                event.startDate,
                event.endDate,
                event.isAllDay,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
