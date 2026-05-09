import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/auth_state.dart';
import '../../../../core/utils/shared_prefs_service.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => _checkAuthStatus());
    return AuthInitial();
  }

  static const String _sessionKey = 'user_session';

  Future<void> _checkAuthStatus() async {
    state = AuthLoading();
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final session = prefs.getString(_sessionKey);
      if (session != null && session.isNotEmpty) {
        state = AuthAuthenticated(session);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError('Failed to load session');
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.isNotEmpty) {
        final prefs = ref.read(sharedPreferencesProvider);
        final savedPassword = prefs.getString('user_$email');
        
        if (savedPassword == password) {
          final mockToken = 'token_$email';
          await prefs.setString(_sessionKey, mockToken);
          state = AuthAuthenticated(mockToken);
        } else {
          state = AuthError('Invalid email or password');
        }
      } else {
        state = AuthError('Please enter email and password');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = AuthLoading();
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
        final prefs = ref.read(sharedPreferencesProvider);
        
        // Save user credentials
        await prefs.setString('user_$email', password);
        await prefs.setString('name_$email', name);
        
        final mockToken = 'token_$email';
        await prefs.setString(_sessionKey, mockToken);
        
        state = AuthAuthenticated(mockToken);
      } else {
        state = AuthError('Invalid inputs. Password must be 6+ chars.');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_sessionKey);
      state = AuthUnauthenticated();
    } catch (e) {
       state = AuthError('Failed to logout: \$e');
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
