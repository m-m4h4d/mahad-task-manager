import 'package:flutter_test/flutter_test.dart';
import 'package:mahad_task_manager/features/auth/data/auth_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final throwsAuth = throwsA(isA<AuthException>());

  group('signUp', () {
    test('creates a signed-in account with a normalized email', () async {
      final repo = AuthRepository(await mockPrefs());
      final account = await repo.signUp(email: ' Alice@Example.com ', password: 'hunter22', name: 'Alice');

      expect(account.userId, 'alice@example.com');
      expect(account.email, 'alice@example.com');
      expect(account.name, 'Alice');
      expect(repo.currentAccount()?.userId, 'alice@example.com');
    });

    test('never stores the password', () async {
      final prefs = await mockPrefs();
      await AuthRepository(prefs).signUp(email: 'a@b.co', password: 'hunter22', name: 'A');

      final stored = prefs.getKeys().map((k) => '${prefs.get(k)}').join();
      expect(stored, isNot(contains('hunter22')));
    });

    test('rejects an email that is already registered, in any case', () async {
      final repo = AuthRepository(await mockPrefs());
      await repo.signUp(email: 'alice@example.com', password: 'hunter22', name: 'Alice');

      await expectLater(repo.signUp(email: 'ALICE@example.com', password: 'other12', name: 'Eve'), throwsAuth);
    });

    test('validates email, password length and name', () async {
      final repo = AuthRepository(await mockPrefs());
      await expectLater(repo.signUp(email: 'not-an-email', password: 'secret1', name: 'A'), throwsAuth);
      await expectLater(repo.signUp(email: 'a@b.co', password: '12345', name: 'A'), throwsAuth);
      await expectLater(repo.signUp(email: 'a@b.co', password: 'secret1', name: '  '), throwsAuth);
    });
  });

  group('login', () {
    late AuthRepository repo;

    setUp(() async {
      repo = AuthRepository(await mockPrefs());
      await repo.signUp(email: 'alice@example.com', password: 'hunter22', name: 'Alice');
      await repo.logout();
    });

    test('succeeds with the right password, ignoring email case', () async {
      final account = await repo.login(email: 'Alice@Example.COM', password: 'hunter22');
      expect(account.userId, 'alice@example.com');
      expect(repo.currentAccount()?.name, 'Alice');
    });

    test('fails with a wrong password or unknown email', () async {
      await expectLater(repo.login(email: 'alice@example.com', password: 'hunter23'), throwsAuth);
      await expectLater(repo.login(email: 'nobody@example.com', password: 'hunter22'), throwsAuth);
      expect(repo.currentAccount(), isNull);
    });

    test('logout clears the session', () async {
      await repo.login(email: 'alice@example.com', password: 'hunter22');
      await repo.logout();
      expect(repo.currentAccount(), isNull);
    });
  });

  group('accounts from the plaintext version', () {
    Future<AuthRepository> legacyRepo() async => AuthRepository(await mockPrefs({
          'user_Bob@Example.com': 'secret1',
          'name_Bob@Example.com': 'Bob',
          'user_session': 'token_Bob@Example.com',
        }));

    test('old sessions are not restored', () async {
      expect((await legacyRepo()).currentAccount(), isNull);
    });

    test('cannot be taken over by signing up again', () async {
      final repo = await legacyRepo();
      await expectLater(repo.signUp(email: 'Bob@Example.com', password: 'takeover', name: 'Eve'), throwsAuth);
    });

    test('are migrated on login, keeping their userId and deleting the plaintext', () async {
      final prefs = await mockPrefs({
        'user_Bob@Example.com': 'secret1',
        'name_Bob@Example.com': 'Bob',
      });
      final repo = AuthRepository(prefs);

      await expectLater(repo.login(email: 'Bob@Example.com', password: 'wrong1'), throwsAuth);
      expect(prefs.getString('user_Bob@Example.com'), 'secret1');

      final account = await repo.login(email: 'Bob@Example.com', password: 'secret1');
      expect(account.userId, 'Bob@Example.com');
      expect(account.email, 'bob@example.com');
      expect(account.name, 'Bob');
      expect(prefs.getString('user_Bob@Example.com'), isNull);
      expect(prefs.getString('name_Bob@Example.com'), isNull);

      await repo.logout();
      expect((await repo.login(email: 'bob@example.com', password: 'secret1')).userId, 'Bob@Example.com');
    });
  });
}
