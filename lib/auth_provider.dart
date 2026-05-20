import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? currentUser;
  final String? errorMessage;

  AuthState({required this.status, this.currentUser, this.errorMessage});

  AuthState copyWith({
    AuthStatus? status,
    UserModel? currentUser,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  SupabaseClient get _sb => SupabaseService.client;

  @override
  AuthState build() {
    Future.microtask(_loadUser);
    return AuthState(status: AuthStatus.loading);
  }

  Future<void> _loadUser() async {
    try {
      final session = _sb.auth.currentSession;
      if (session != null) {
        final user = await _fetchProfile(session.user.id, session.user.email);
        state = AuthState(status: AuthStatus.authenticated, currentUser: user);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<UserModel> _fetchProfile(String uid, String? email) async {
    final data = await _sb
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data != null) {
      return UserModel.fromSupabase(data, email: email ?? '');
    }
    // Profile may not exist yet — return minimal model.
    return UserModel(
      id: uid,
      name: '',
      username: '',
      email: email ?? '',
      age: 0,
      country: 'United States',
    );
  }

  // ─── Register ─────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required int age,
    required String country,
    required String password,
  }) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      // Check username uniqueness
      final existing = await _sb
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (existing != null) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: 'Username is already taken.',
        );
        return false;
      }

      final response = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: 'Registration failed. Please try again.',
        );
        return false;
      }

      final uid = response.user!.id;
      await _sb.from('profiles').insert({
        'id': uid,
        'name': name,
        'username': username,
        'age': age,
        'country': country,
      });

      final user = UserModel(
        id: uid,
        name: name,
        username: username,
        email: email,
        age: age,
        country: country,
      );
      state = AuthState(status: AuthStatus.authenticated, currentUser: user);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong: $e',
      );
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: 'Invalid email or password.',
        );
        return false;
      }

      final user = await _fetchProfile(response.user!.id, response.user!.email);
      state = AuthState(status: AuthStatus.authenticated, currentUser: user);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong: $e',
      );
      return false;
    }
  }

  // ─── Reset Password ───────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _sb.auth.resetPasswordForEmail(email.trim());
      state = AuthState(status: AuthStatus.unauthenticated);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong: $e',
      );
      return false;
    }
  }

  // ─── Update Profile ───────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String username,
    required int age,
    required String country,
  }) async {
    if (state.currentUser == null) return;
    try {
      await _sb.from('profiles').update({
        'name': name,
        'username': username,
        'age': age,
        'country': country,
      }).eq('id', state.currentUser!.id);

      final updated = state.currentUser!.copyWith(
        name: name,
        username: username,
        age: age,
        country: country,
      );
      state = state.copyWith(currentUser: updated);
    } catch (_) {}
  }

  // ─── Logout ──────────────────────────────────────────────
  Future<void> logout() async {
    await _sb.auth.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());