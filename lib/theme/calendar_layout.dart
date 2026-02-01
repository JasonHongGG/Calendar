class CalendarLayout {
  // Calendar Card Layout
  static const double monthContainerHeight = 520.0;

  // Internal dimensions
  // Estimated height for the weekday header (vertical padding 12*2 + text ~18)
  static const double weekdayHeaderHeight = 48.0;

  // The available height for the grid.
  // We leave some buffer for divider (1px) and padding.
  static const double monthGridTargetHeight =
      monthContainerHeight - weekdayHeaderHeight - 8.0;

  // Event Layout
  static const double dayLabelHeight = 34.0;
  static const double eventRowHeight = 18.0;
  static const double eventSpacing = 2.0;
}
