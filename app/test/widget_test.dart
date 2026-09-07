// Smoke test for critical flow #1 (section 16): "A new learner enters guest mode and selects
// subjects." Runs the real app widget tree (no Supabase configured => local dev mode) against an
// in-memory local database, and walks splash -> subject selection -> diagnostic assessment -> home.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matricquest_sa/app.dart';
import 'package:matricquest_sa/core/providers.dart';
import 'package:matricquest_sa/data/local/app_database.dart';

void main() {
  testWidgets('guest learner reaches subject selection then home', (
    tester,
  ) async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MatricQuestApp(),
      ),
    );

    // Splash screen shows the app name, then auto-navigates.
    expect(find.text('MatricQuest SA'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Should now be on subject selection (onboarding not yet complete for a fresh guest).
    expect(find.text('Choose your subjects'), findsOneWidget);

    // Select the demo Mathematics subject and continue.
    expect(find.text('Mathematics'), findsOneWidget);
    final mathematicsTile = find.ancestor(
      of: find.text('Mathematics'),
      matching: find.byType(CheckboxListTile),
    );
    expect(mathematicsTile, findsOneWidget);

    // Tap the tile's own Checkbox (a direct descendant) rather than the tile bounds generally —
    // more reliable to hit-test than the ancestor's full row.
    final checkbox = find.descendant(
      of: mathematicsTile,
      matching: find.byType(Checkbox),
    );
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox, warnIfMissed: false);
    await tester.pumpAndSettle();

    // The continue button sits below the fold in the test surface's default viewport — the
    // ListView only builds children near the visible/cache extent, so scroll it into view.
    await tester.scrollUntilVisible(
      find.textContaining('Continue ('),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('Continue (1 selected)'), findsOneWidget);
    final continueButton = find.widgetWithText(
      FilledButton,
      'Continue (1 selected)',
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // Landed on the diagnostic assessment for the demo Mathematics topic.
    expect(find.text('Quick Check'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.textContaining('Start ('), findsOneWidget);

    // Skip it — this is the "learner declines the diagnostic" path; the study plan generator
    // already treats that the same as "not started", so nothing further to assert about mastery
    // here specifically (see test/domain/study_plan_repository_test.dart for that).
    await tester.tap(find.text('Skip this subject'));
    await tester.pumpAndSettle();

    // Only one topic is available in local dev mode, so skipping it goes straight to the summary.
    expect(find.text('Your starting point'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);

    await tester.tap(find.text('Continue to MatricQuest SA'));
    await tester.pumpAndSettle();

    // Landed on Home with bottom navigation visible. "Learn"/"Papers" appear twice each (once as
    // a dashboard shortcut button, once as a bottom-nav destination) — findsWidgets is correct.
    expect(find.text('Recommended next lesson'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Papers'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
  });
}
