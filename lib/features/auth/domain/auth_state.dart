abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final String sessionToken;
  AuthAuthenticated(this.sessionToken);

  /// The signed-in user's email, which identifies them in this mock auth.
  String get userId => sessionToken.replaceFirst('token_', '');
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
