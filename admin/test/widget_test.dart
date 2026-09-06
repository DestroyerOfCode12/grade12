// Smoke test: with no Supabase project configured (the default for a fresh checkout — see
// admin/.env.example), the app must show the "not connected" screen rather than crash. This is
// the only state this app can meaningfully reach without a real backend, since — unlike the
// mobile app — there is no local dev mode for an admin tool whose entire job is editing real data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_admin/app.dart';

void main() {
  testWidgets(
    'shows the not-connected screen when no Supabase project is configured',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MatricQuestAdminApp()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Supabase project configured'), findsOneWidget);
      // Must not silently render an empty dashboard as if data loaded successfully.
      expect(find.text('Dashboard'), findsNothing);
    },
  );
}
