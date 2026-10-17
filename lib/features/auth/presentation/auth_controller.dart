import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // SharedPreferences is loaded before the app starts, so the session can be
    // restored synchronously without briefly showing the login screen.
    final account = _repository.currentAccount();
    return account == null ? AuthUnauthenticated() : _authenticated(account);
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = AuthError('Please enter email and password');
      return;
    }
    await _run(() => _repository.login(email: email, password: password));
  }

  Future<void> signUp(String email, String password, String name) async {
    await _run(() => _repository.signUp(email: email, password: password, name: name));
  }

  Future<void> logout() async {
    state = AuthLoading();
    try {
      await _repository.logout();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Failed to logout: $e');
    }
  }

  Future<void> _run(Future<Account> Function() action) async {
    state = AuthLoading();
    try {
      state = _authenticated(await action());
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  AuthAuthenticated _authenticated(Account account) =>
      AuthAuthenticated(userId: account.userId, email: account.email, name: account.name);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user's id, or null when nobody is signed in.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState is AuthAuthenticated ? authState.userId : null;
});
