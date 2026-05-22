import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_model.dart';
import 'hive_storage.dart';

enum AuthStatus { initial, loading, authenticated, error }

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
  static const String _defaultUserId = 'local_user';
  static const String _defaultUsername = 'HabitFlow User';

  @override
  AuthState build() {
    Future.microtask(_loadUser);
    return AuthState(status: AuthStatus.loading);
  }

  /// Load the local user profile or create default if doesn't exist
  Future<void> _loadUser() async {
    try {
      final userBox = HiveStorage.userBox;
      var user = userBox.get(_defaultUserId);

      if (user == null) {
        // Create default local user
        user = UserModel(
          id: _defaultUserId,
          name: _defaultUsername,
          username: _defaultUsername,
          email: '',
          age: 0,
          country: 'United States',
        );
        await userBox.put(_defaultUserId, user);
      }

      state = AuthState(status: AuthStatus.authenticated, currentUser: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Failed to load user profile: $e',
      );
    }
  }

  /// Update user profile locally
  Future<void> updateProfile({
    required String name,
    required String username,
    required int age,
    required String country,
  }) async {
    if (state.currentUser == null) return;
    
    try {
      final updated = state.currentUser!.copyWith(
        name: name,
        username: username,
        age: age,
        country: country,
      );
      
      await HiveStorage.userBox.put(_defaultUserId, updated);
      state = state.copyWith(currentUser: updated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to update profile: $e',
      );
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState(status: AuthStatus.authenticated, currentUser: state.currentUser);
    } else {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());