import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/calendar_layout.dart';
import '../utils/date_utils.dart';
import '../widgets/gradient_header.dart';
import '../widgets/month_calendar.dart';
import '../widgets/add_event_sheet.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/date_selector_modal.dart';
import '../widgets/sticker_picker_sheet.dart';
import 'settings_page.dart';

/// 月視圖頁面
class MonthViewPage extends StatefulWidget {
  const MonthViewPage({super.key});

  @override
  State<MonthViewPage> createState() => _MonthViewPageState();
}

class _MonthViewPageState extends State<MonthViewPage> {
  late PageController _pageController;
  Timer? _prewarmTimer;
  String? _lastPrewarmKey;
  // Epoch: 2020/01 is index 0
  static const int _startYear = 2020;
  static const int _startMonth = 1;

  @override
  void initState() {
    super.initState();
    // Initialize controller based on provider's current month
    final provider = context.read<EventProvider>();
    final initialIndex = _calculateIndex(provider.currentMonth);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync controller if provider changed externally (e.g. "Today" action elsewhere)
    final provider = context.read<EventProvider>();
    final currentIndex = _calculateIndex(provider.currentMonth);
    if (_pageController.hasClients && _pageController.page?.round() != currentIndex) {
      _pageController.jumpToPage(currentIndex);
    }
  }

  @override
  void dispose() {
    _prewarmTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int _calculateIndex(DateTime date) {
    return (date.year - _startYear) * 12 + (date.month - _startMonth);
  }

  DateTime _calculateDateFromIndex(int index) {
    return DateTime(_startYear, _startMonth + index);
  }

  void _showDateSelector(BuildContext context, DateTime currentMonth) {
    showDialog(
      context: context,
      builder: (context) => DateSelectorModal(
        initialDate: currentMonth,
        onConfirm: (selectedDate) {
          final index = _calculateIndex(selectedDate);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }

  void _showStickerPicker(BuildContext context, DateTime date) {
    showStickerPickerSheet(context: context, date: date);
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = context.watch<EventProvider>().currentMonth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = _calculateIndex(currentMonth);
      if (_pageController.hasClients && _pageController.page?.round() != targetIndex) {
        _pageController.jumpToPage(targetIndex);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimens.spacingSmall),
            // Header: Only this part needs to rebuild when month changes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal),
              child: CalendarHeader(
                title: '${currentMonth.year}/${currentMonth.month.toString().padLeft(2, '0')}',
                onPrevious: () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                onNext: () {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                onTitleTap: () => _showDateSelector(context, currentMonth),
                onTodayTap: () {
                  final now = DateTime.now();
                  final index = _calculateIndex(now);
                  _pageController.jumpToPage(index);
                },
                onSettings: () {
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
            ),

            // Static Calendar Background & Header
            // The PageView will slide strictly inside this container
            Container(
              height: CalendarLayout.monthContainerHeight,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingNormal),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
                boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // Static Weekday Header (Doesn't move)
                  _buildWeekdayHeader(),
                  const Divider(height: 1),

                  // Sliding Date Grid
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      allowImplicitScrolling: true,
                      onPageChanged: (index) {
                        final provider = context.read<EventProvider>();
                        final newMonth = _calculateDateFromIndex(index);
                        if (newMonth.year != provider.currentMonth.year || newMonth.month != provider.currentMonth.month) {
                          provider.setCurrentMonth(newMonth);
                        }
                        _prewarmTimer?.cancel();
                        _prewarmTimer = Timer(const Duration(milliseconds: 180), () {
                          if (!mounted) return;
                          final events = provider.events;
                          final eventsVersion = provider.eventsVersion;
                          final nextMonth = _calculateDateFromIndex(index + 1);
                          final prewarmKey = '${nextMonth.year}-${nextMonth.month}-$eventsVersion';
                          if (_lastPrewarmKey == prewarmKey) return;
                          _lastPrewarmKey = prewarmKey;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            MonthCalendar.prewarm(events, nextMonth, eventsVersion);
                          });
                        });
                      },
                      itemBuilder: (context, index) {
                        final monthDate = _calculateDateFromIndex(index);
                        return Selector<EventProvider, DateTime>(
                          selector: (context, provider) => provider.selectedDate,
                          builder: (context, selectedDate, child) {
                            return MonthCalendar(
                              currentMonth: monthDate,
                              selectedDate: selectedDate,
                              onDateSelected: (date) {
                                final provider = context.read<EventProvider>();
                                // 如果已經選中該日期，則打開詳情頁
                                if (CalendarDateUtils.isSameDay(date, selectedDate)) {
                                  showDialog(
                                    context: context,
                                    barrierColor: Colors.black54,
                                    builder: (context) => DayDetailSheet(date: date),
                                  );
                                } else {
                                  // 否則只是切換選中日期
                                  provider.setSelectedDate(date);
                                }
                              },
                              onDateLongPress: (date) => _showStickerPicker(context, date),
                              onEventTap: (event) {
                                showAddEventSheet(context, editEvent: event, initialDate: event.startDate);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // FAB removed; add action is in navigation bar
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
