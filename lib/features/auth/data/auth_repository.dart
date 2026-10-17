import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/shared_prefs_service.dart';

/// A locally registered account.
class Account {
  /// Stable id that owns this account's tasks. For new accounts it is the
  /// normalized email; accounts migrated from the old storage keep the email
  /// exactly as it was typed at sign-up so their tasks stay attached.
  final String userId;
  final String email;
  final String name;

  const Account({required this.userId, required this.email, required this.name});
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Local, device-only account storage. Passwords are never stored: each
/// account keeps a random salt and a PBKDF2-HMAC-SHA256 hash (computed with
/// the browser's Web Crypto API on web, and in Dart elsewhere).
///
/// This is still not real authentication. Everything lives in
/// SharedPreferences on the device, so anyone with access to the device's
/// storage can read or replace it. A backend is needed for that.
class AuthRepository {
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  static const String _sessionKey = 'user_session';
  static const String _accountPrefix = 'account_';
  static const int _iterations = 100000;
  static const int _saltLength = 16;
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) => _emailPattern.hasMatch(normalizeEmail(email));

  /// The account that is currently signed in, if any.
  Account? currentAccount() {
    final email = _prefs.getString(_sessionKey);
    if (email == null) return null;
    final record = _readRecord(email);
    return record == null ? null : _toAccount(email, record);
  }

  Future<Account> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      throw const AuthException('Please enter a valid email');
    }
    if (password.length < minPasswordLength) {
      throw const AuthException('Password must be at least $minPasswordLength characters');
    }
    if (name.trim().isEmpty) {
      throw const AuthException('Please enter your name');
    }
    if (_readRecord(normalized) != null || _legacyPassword(email) != null) {
      throw const AuthException('An account with this email already exists');
    }

    await _writeRecord(normalized, userId: normalized, name: name.trim(), password: password);
    await _prefs.setString(_sessionKey, normalized);
    return currentAccount()!;
  }

  Future<Account> login({required String email, required String password}) async {
    final normalized = normalizeEmail(email);
    final record = _readRecord(normalized);

    if (record == null) {
      final account = await _migrateLegacyAccount(email, password);
      if (account == null) throw const AuthException('Invalid email or password');
      return account;
    }

    final salt = base64Decode(record['salt'] as String);
    final iterations = record['iterations'] as int;
    final expected = base64Decode(record['hash'] as String);
    if (!_constantTimeEquals(await _hash(password, salt, iterations), expected)) {
      throw const AuthException('Invalid email or password');
    }

    await _prefs.setString(_sessionKey, normalized);
    return _toAccount(normalized, record);
  }

  Future<void> logout() async {
    await _prefs.remove(_sessionKey);
  }

  /// Accounts created before passwords were hashed were stored as
  /// `user_<email>` = plaintext password and `name_<email>` = name, with the
  /// email exactly as typed. On a successful login, move the account to the
  /// hashed format and delete the plaintext password.
  Future<Account?> _migrateLegacyAccount(String email, String password) async {
    final rawEmail = email.trim();
    final saved = _legacyPassword(rawEmail);
    if (saved == null || saved != password) return null;

    final normalized = normalizeEmail(rawEmail);
    await _writeRecord(
      normalized,
      userId: rawEmail,
      name: _prefs.getString('name_$rawEmail') ?? '',
      password: password,
    );
    await _prefs.remove('user_$rawEmail');
    await _prefs.remove('name_$rawEmail');
    await _prefs.setString(_sessionKey, normalized);
    return currentAccount();
  }

  String? _legacyPassword(String email) => _prefs.getString('user_${email.trim()}');

  Map<String, dynamic>? _readRecord(String normalizedEmail) {
    final raw = _prefs.getString('$_accountPrefix$normalizedEmail');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeRecord(
    String normalizedEmail, {
    required String userId,
    required String name,
    required String password,
  }) async {
    final salt = _randomBytes(_saltLength);
    await _prefs.setString(
      '$_accountPrefix$normalizedEmail',
      jsonEncode({
        'userId': userId,
        'name': name,
        'salt': base64Encode(salt),
        'iterations': _iterations,
        'hash': base64Encode(await _hash(password, salt, _iterations)),
      }),
    );
  }

  Account _toAccount(String normalizedEmail, Map<String, dynamic> record) => Account(
        userId: record['userId'] as String,
        email: normalizedEmail,
        name: record['name'] as String,
      );

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static Future<List<int>> _hash(String password, List<int> salt, int iterations) async {
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(sharedPreferencesProvider));
});
