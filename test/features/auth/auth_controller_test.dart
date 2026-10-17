import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahad_task_manager/core/utils/shared_prefs_service.dart';
import 'package:mahad_task_manager/features/auth/domain/auth_state.dart';
import 'package:mahad_task_manager/features/auth/presentation/auth_controller.dart';

import '../../helpers/test_helpers.dart';

void main() {
  ProviderContainer containerFor(SharedPreferences prefs) {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts signed out with no saved session', () async {
    final container = containerFor(await mockPrefs());
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
    expect(container.read(currentUserIdProvider), isNull);
  });

  test('sign up signs the user in and the session survives a restart', () async {
    final prefs = await mockPrefs();
    final first = containerFor(prefs);
    await first.read(authControllerProvider.notifier).signUp('cee@example.com', 'secret1', 'Cee');
    expect(first.read(currentUserIdProvider), 'cee@example.com');

    final restarted = containerFor(prefs);
    final state = restarted.read(authControllerProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).name, 'Cee');
  });

  test('reports errors as AuthError', () async {
    final container = containerFor(await mockPrefs());
    final auth = container.read(authControllerProvider.notifier);

    await auth.login('', '');
    expect((container.read(authControllerProvider) as AuthError).message, 'Please enter email and password');

    await auth.login('nobody@example.com', 'secret1');
    expect((container.read(authControllerProvider) as AuthError).message, 'Invalid email or password');
  });

  test('logout signs the user out', () async {
    final container = containerFor(await mockPrefs());
    final auth = container.read(authControllerProvider.notifier);
    await auth.signUp('cee@example.com', 'secret1', 'Cee');

    await auth.logout();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
    expect(container.read(currentUserIdProvider), isNull);
  });
}
