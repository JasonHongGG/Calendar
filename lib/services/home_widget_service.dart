import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetService {
  static const String _fallbackImagePathKey = 'month_image_path';
  static const String _monthImagePathPrefix = 'month_image_path_';
  static const String _widgetMonthKey = 'widget_month_key';

  static Future<void> updateMonthWidgetFromBoundary(GlobalKey boundaryKey, DateTime month, {bool setAsCurrent = false, String? filenameSuffix}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    await WidgetsBinding.instance.endOfFrame;
    // Add a small delay to ensure the widget is fully repainted with new settings
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (boundary.size.isEmpty) return;

    print('HomeWidgetService: Capturing snapshot for $month');

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    image.dispose();

    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final monthKey = _formatMonthKey(month);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'month_widget_$monthKey${filenameSuffix != null ? '_$filenameSuffix' : ''}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await HomeWidget.saveWidgetData<String>('$_monthImagePathPrefix$monthKey', file.path);
    if (setAsCurrent) {
      await HomeWidget.saveWidgetData<String>(_widgetMonthKey, monthKey);
      await HomeWidget.saveWidgetData<String>(_fallbackImagePathKey, file.path);
      await HomeWidget.updateWidget(name: 'CalendarMonthWidgetProvider', androidName: 'CalendarMonthWidgetProvider');
    }
  }

  static String _formatMonthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }
}
