import 'package:flutter/material.dart';

enum MonthEventTitleSize { medium, large, xlarge }

class SettingsProvider extends ChangeNotifier {
  MonthEventTitleSize _monthEventTitleSize = MonthEventTitleSize.medium;

  MonthEventTitleSize get monthEventTitleSize => _monthEventTitleSize;

  void setMonthEventTitleSize(MonthEventTitleSize size) {
    if (_monthEventTitleSize == size) return;
    _monthEventTitleSize = size;
    notifyListeners();
  }

  double get monthEventRowHeight {
    switch (_monthEventTitleSize) {
      case MonthEventTitleSize.large:
        return 20;
      case MonthEventTitleSize.xlarge:
        return 24;
      case MonthEventTitleSize.medium:
        return 17;
    }
  }

  double get monthEventFontSize {
    switch (_monthEventTitleSize) {
      case MonthEventTitleSize.large:
        return 12;
      case MonthEventTitleSize.xlarge:
        return 14;
      case MonthEventTitleSize.medium:
        return 10;
    }
  }

  double get monthEventOverflowFontSize {
    switch (_monthEventTitleSize) {
      case MonthEventTitleSize.large:
        return 12;
      case MonthEventTitleSize.xlarge:
        return 13;
      case MonthEventTitleSize.medium:
        return 11;
    }
  }

  double get monthEventSpacing {
    switch (_monthEventTitleSize) {
      case MonthEventTitleSize.xlarge:
        return 2;
      case MonthEventTitleSize.large:
        return 1.5;
      case MonthEventTitleSize.medium:
        return 1;
    }
  }
}
