import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Google Sign-In ────────────────────────────────────────────────────────

  static Future<AuthResult?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      return AuthResult(
        email: account.email,
        name: account.displayName ?? 'Engineer',
        photoUrl: account.photoUrl,
        googleId: account.id,
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }

  // ── Local session ─────────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String userId,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
  }

  static Future<SavedSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);

    if (userId == null || email == null) return null;

    return SavedSession(
      userId: userId,
      email: email,
      name: name ?? 'Engineer',
    );
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }
}

class AuthResult {
  final String email;
  final String name;
  final String? photoUrl;
  final String googleId;

  AuthResult({
    required this.email,
    required this.name,
    this.photoUrl,
    required this.googleId,
  });
}

class SavedSession {
  final String userId;
  final String email;
  final String name;

  SavedSession({
    required this.userId,
    required this.email,
    required this.name,
  });
}
