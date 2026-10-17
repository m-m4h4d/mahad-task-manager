import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahad_task_manager/core/utils/shared_prefs_service.dart';
import 'package:mahad_task_manager/features/auth/data/auth_repository.dart';
import 'package:mahad_task_manager/features/tasks/presentation/task_list_screen.dart';
import 'package:mahad_task_manager/main.dart';

import 'helpers/test_helpers.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, SharedPreferences prefs) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Keep the dashboard off the platform database.
          taskListProvider.overrideWith((ref) async => [task('Water the plants', id: 1)]),
        ],
        child: const TaskPulseApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the login screen when signed out', (tester) async {
    await pumpApp(tester, await mockPrefs());

    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });

  testWidgets('logging in opens the dashboard with the user\'s tasks', (tester) async {
    final prefs = await mockPrefs();
    await tester.runAsync(() async {
      final repo = AuthRepository(prefs);
      await repo.signUp(email: 'alice@example.com', password: 'hunter22', name: 'Alice');
      await repo.logout();
    });
    await pumpApp(tester, prefs);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'alice@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'hunter22');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    // Password hashing does real async work, so let it finish outside fake time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pumpAndSettle();

    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgets('a saved session skips the login screen', (tester) async {
    final prefs = await mockPrefs();
    await tester.runAsync(() => AuthRepository(prefs)
        .signUp(email: 'alice@example.com', password: 'hunter22', name: 'Alice'));
    await pumpApp(tester, prefs);

    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsNothing);
  });
}
