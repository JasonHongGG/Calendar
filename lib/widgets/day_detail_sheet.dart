import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart';
import 'add_event_sheet.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime date;

  const DayDetailSheet({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // Watch events for the specific date
    final events = context.select<EventProvider, List<Event>>((p) => p.getEventsForDate(date));

    final tone = context.select<SettingsProvider, EventColorTone>((s) => s.eventColorTone);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        constraints: const BoxConstraints(maxHeight: 500, minHeight: 400),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date + Weekday
                        Row(
                          children: [
                            Text(
                              '${date.day}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              CalendarDateUtils.formatWeekday(date),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Lunar Date
                        Text(
                          '農曆日期 ${date.month}月${date.day}日', // Placeholder
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Add Button (Moved from footer)
                  IconButton.filled(
                    onPressed: () {
                      showAddEventSheet(context, initialDate: date);
                    },
                    style: IconButton.styleFrom(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary),
                    icon: const Icon(Icons.add, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.dividerLight),
            const SizedBox(height: 8),

            // Event List
            Expanded(
              child: events.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _buildEventItem(context, events[index], tone);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '沒有活動',
            style: TextStyle(fontSize: 16, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Event event, EventColorTone tone) {
    final eventColor = AppColors.eventColor(event.colorKey, tone: tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showAddEventSheet(context, editEvent: event, initialDate: event.startDate);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.event_rounded, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                // Bar
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(color: eventColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(CalendarDateUtils.formatTimeRange(event.startDate, event.endDate, event.isAllDay), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
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
