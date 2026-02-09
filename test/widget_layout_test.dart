import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:calendar/widgets/month_widget_snapshot.dart';
import 'package:calendar/providers/event_provider.dart';
import 'package:calendar/providers/settings_provider.dart';
import 'package:calendar/providers/date_sticker_provider.dart';
import 'package:calendar/models/event.dart';
import 'package:calendar/theme/calendar_layout.dart';
import 'package:calendar/theme/app_colors.dart';

class FakeEventProvider extends ChangeNotifier implements EventProvider {
  @override
  List<Event> get events => [];
  
  @override
  int get eventsVersion => 0;

  @override
  DateTime get currentMonth => DateTime.now();

  @override
  DateTime get selectedDate => DateTime.now();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  double get monthEventRowHeight => 17.0;
  
  @override
  double get monthEventSpacing => 1.0;

  @override
  double get monthEventFontSize => 11.0;

  @override
  double get monthEventOverflowFontSize => 10.0;
  
  @override
  EventColorTone get eventColorTone => EventColorTone.normal;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDateStickerProvider extends ChangeNotifier implements DateStickerProvider {
  @override
  String? getStickerEmoji(DateTime date) => null;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MonthWidgetSnapshot layout for April 2026', (WidgetTester tester) async {
    // April 2026 has 5 weeks
    final month = DateTime(2026, 4);
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EventProvider>(create: (_) => FakeEventProvider()),
          ChangeNotifierProvider<SettingsProvider>(create: (_) => FakeSettingsProvider()),
          ChangeNotifierProvider<DateStickerProvider>(create: (_) => FakeDateStickerProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: MonthWidgetSnapshot(month: month),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify overall height
    final snapshotFinder = find.byType(MonthWidgetSnapshot);
    final snapshotSize = tester.getSize(snapshotFinder);
    
    print('Snapshot Size: $snapshotSize');
    
    expect(snapshotSize.height, equals(CalendarLayout.monthContainerHeight));
  });
}
