import 'package:intl/intl.dart';

/// 日期工具類
class CalendarDateUtils {
  CalendarDateUtils._();

  /// 取得月份的第一天
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 取得月份的最後一天
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 取得月曆顯示的第一天（可能是上個月的日期）
  /// 以週一為一週的開始
  static DateTime getCalendarStartDate(DateTime date) {
    final firstDay = getFirstDayOfMonth(date);
    // weekday: 1=週一, 7=週日
    // 如果是週日(7)，餘數為0，不減
    // 如果是週一(1)，餘數為1，減1天
    final daysToSubtract = firstDay.weekday % 7;
    return firstDay.subtract(Duration(days: daysToSubtract));
  }

  /// 取得指定月份需要顯示的所有日期（6週 = 42天）
  static List<DateTime> getCalendarDays(DateTime month) {
    final startDate = getCalendarStartDate(month);
    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  /// 檢查兩個日期是否為同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 檢查日期是否為今天
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 檢查日期是否在指定月份
  static bool isInMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  /// 格式化日期為年月（如：2026年1月）
  static String formatYearMonth(DateTime date) {
    return DateFormat('yyyy年M月', 'zh_TW').format(date);
  }

  /// 格式化日期（如：1月31日）
  static String formatMonthDay(DateTime date) {
    return DateFormat('M月d日', 'zh_TW').format(date);
  }

  /// 格式化日期（如：2026年1月31日）
  static String formatYearMonthDay(DateTime date) {
    return DateFormat('yyyy年M月d日', 'zh_TW').format(date);
  }

  /// 格式化日期（如：02/01）
  static String formatMonthDaySlash(DateTime date) {
    return DateFormat('MM/dd', 'zh_TW').format(date);
  }

  /// 格式化日期（如：2026/02/01）
  static String formatYearMonthDaySlash(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'zh_TW').format(date);
  }

  /// 格式化年份（如：2026）
  static String formatYear(DateTime date) {
    return DateFormat('yyyy', 'zh_TW').format(date);
  }

  /// 格式化星期（如：週六）
  static String formatWeekday(DateTime date) {
    const weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return weekdays[date.weekday - 1];
  }

  /// 格式化時間（如：09:00）
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化日期範圍用於顯示
  static String formatDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatMonthDay(start);
    }
    return '${formatMonthDay(start)} - ${formatMonthDay(end)}';
  }

  /// 格式化時間範圍
  static String formatTimeRange(DateTime start, DateTime end, bool isAllDay) {
    if (isAllDay) return '全天';
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// 取得星期標題列表
  static List<String> get weekdayLabels => ['日', '一', '二', '三', '四', '五', '六'];

  /// 檢查日期是否為周末
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 取得日期的純日期部分（不含時間）
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 比較兩個日期的先後（僅比較日期部分）
  static int compareDates(DateTime a, DateTime b) {
    return dateOnly(a).compareTo(dateOnly(b));
  }

  /// 格式化事件時間（包含日期與時間）
  static String formatEventTime(DateTime start, DateTime end, bool isAllDay) {
    if (isAllDay) {
      if (isSameDay(start, end)) {
        return '${formatYearMonthDaySlash(start)} 全天';
      } else {
        return '${formatYearMonthDaySlash(start)} - ${formatYearMonthDaySlash(end)}';
      }
    }

    if (isSameDay(start, end)) {
      return '${formatYearMonthDaySlash(start)} ${formatTime(start)} - ${formatTime(end)}';
    } else {
      return '${formatYearMonthDaySlash(start)} ${formatTime(start)} - ${formatYearMonthDaySlash(end)} ${formatTime(end)}';
    }
  }
}
