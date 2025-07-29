// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calorie_tracker_app/main.dart';

void main() {
  testWidgets('Calorie tracker app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CalorieTrackerApp());

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('卡路里追踪器'), findsWidgets);

    // Verify that the app loads without errors
    expect(find.byType(CalorieTrackerApp), findsOneWidget);
  });
}
