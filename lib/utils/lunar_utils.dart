import 'package:lunar/lunar.dart';

class LunarUtils {
  LunarUtils._();

  /// 取得農曆顯示文字
  /// 優先級：節氣 > 農曆節日(暫不處理，由外部事件控制) > 初一(顯示月份) > 日期
  static String getLunarText(DateTime date) {
    final lunar = Lunar.fromDate(date);

    // 1. 節氣 (如：立春)
    final jieQi = lunar.getJieQi();
    if (jieQi.isNotEmpty) {
      return jieQi;
    }

    // 2. 初一顯示月份 (如：正月)
    if (lunar.getDay() == 1) {
      return '${lunar.getMonthInChinese()}月';
    }

    // 3. 一般日期 (如：初二、廿五)
    return lunar.getDayInChinese();
  }
}
