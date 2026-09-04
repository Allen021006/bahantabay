import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionSnapshot {
  const AuthSessionSnapshot({required this.isSignedIn, this.email});

  final bool isSignedIn;
  final String? email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

abstract interface class AuthService {
  bool get hasActiveSession;
  String? get currentUserEmail;
  Stream<AuthSessionSnapshot> get sessionChanges;

  Future<void> signIn({required String email, required String password});
  Future<bool> signUp({required String email, required String password});
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get hasActiveSession => _client.auth.currentSession != null;

  @override
  String? get currentUserEmail => _client.auth.currentUser?.email;

  @override
  Stream<AuthSessionSnapshot> get sessionChanges {
    return _client.auth.onAuthStateChange.map((state) {
      return AuthSessionSnapshot(
        isSignedIn: state.session != null,
        email: state.session?.user.email,
      );
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response.session != null;
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }
}
