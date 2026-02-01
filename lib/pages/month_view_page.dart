import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/calendar_layout.dart';

import '../widgets/gradient_header.dart';
import '../widgets/month_calendar.dart';

import '../widgets/add_event_sheet.dart';

/// 月視圖頁面
class MonthViewPage extends StatefulWidget {
  const MonthViewPage({super.key});

  @override
  State<MonthViewPage> createState() => _MonthViewPageState();
}

class _MonthViewPageState extends State<MonthViewPage> {
  late PageController _pageController;
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
    // Note: This might trigger during component build, so be careful.
    // Ideally, we listen to the provider in a way that doesn't conflict with onPageChanged.
    // But since onPageChanged drives the provider, this check prevents loops if logic is correct.
    final provider = context.read<EventProvider>();
    final currentIndex = _calculateIndex(provider.currentMonth);
    if (_pageController.hasClients &&
        _pageController.page?.round() != currentIndex) {
      _pageController.jumpToPage(currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateIndex(DateTime date) {
    return (date.year - _startYear) * 12 + (date.month - _startMonth);
  }

  DateTime _calculateDateFromIndex(int index) {
    return DateTime(_startYear, _startMonth + index);
  }

  @override
  Widget build(BuildContext context) {
    // Avoid watching at the top level to prevent PageView rebuilds
    // final provider = context.watch<EventProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Only this part needs to rebuild when month changes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<EventProvider>(
                builder: (context, provider, child) {
                  final currentMonth = provider.currentMonth;
                  return CalendarHeader(
                    title:
                        '${currentMonth.year}/${currentMonth.month.toString().padLeft(2, '0')}',
                    onPrevious: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    onNext: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    onSettings: () {
                      // TODO: Navigate to settings page
                    },
                  );
                },
              ),
            ),

            // Static Calendar Background & Header
            // The PageView will slide strictly inside this container
            Container(
              height: CalendarLayout
                  .monthContainerHeight, // Use centralized constant
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                        if (newMonth.year != provider.currentMonth.year ||
                            newMonth.month != provider.currentMonth.month) {
                          provider.setCurrentMonth(newMonth);
                        }
                      },
                      itemBuilder: (context, index) {
                        final monthDate = _calculateDateFromIndex(index);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              MonthCalendar(
                                currentMonth: monthDate,
                                onEventTap: (event) {
                                  showAddEventSheet(
                                    context,
                                    editEvent: event,
                                    initialDate: event.startDate,
                                  );
                                },
                              ),
                              const Spacer(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Bottom spacing (if needed, or consumed by Expanded margin)
          ],
        ),
      ),
      // FAB needs to listen to selectedDate changes
      floatingActionButton: Selector<EventProvider, DateTime>(
        selector: (context, provider) => provider.selectedDate,
        builder: (context, selectedDate, child) {
          return _buildFAB(context, selectedDate);
        },
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    // Import CalendarDateUtils at top if missing, but it should be available via date_utils.dart
    // Assuming CalendarDateUtils is imported or we can add import.
    // If not imported previously, I should check.
    // MonthViewPage.dart imports:
    // import '../utils/date_utils.dart'; (Removed in step 5 edit? No, step 5 removed it. I MUST RE-ADD IT)

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, DateTime selectedDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () =>
              showAddEventSheet(context, initialDate: selectedDate),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
