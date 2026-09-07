import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/core/providers.dart';
import 'package:matricquest_sa/data/local/app_database.dart';
import 'package:matricquest_sa/features/planner/study_planner_screen.dart';

void main() {
  testWidgets('shows the empty state before any plan has been generated', (
    tester,
  ) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: StudyPlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No study plan yet'), findsOneWidget);
    expect(find.text('Generate my study plan'), findsOneWidget);
  });
}
