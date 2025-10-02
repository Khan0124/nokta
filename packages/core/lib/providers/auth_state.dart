// packages/core/lib/providers/auth_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

sealed class AuthState {
  const AuthState();
  
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    return switch (this) {
      Initial() => initial(),
      Loading() => loading(),
      Authenticated(user: final user) => authenticated(user),
      Unauthenticated() => unauthenticated(),
      Error(message: final message) => error(message),
    };
  }
}

class Initial extends AuthState {
  const Initial();
}

class Loading extends AuthState {
  const Loading();
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Error extends AuthState {
  final String message;
  const Error(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const Initial()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    if (await _authService.isTokenValid()) {
      // Fetch user profile
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = Authenticated(user);
      } else {
        state = const Unauthenticated();
      }
    } else {
      state = const Unauthenticated();
    }
  }
  
  Future<void> login(String username, String password, String tenantId) async {
    state = const Loading();
    
    final result = await _authService.login(
      username: username,
      password: password,
      tenantId: tenantId,
    );
    
    if (result.success && result.user != null) {
      state = Authenticated(result.user!);
    } else {
      state = Error(result.message ?? 'Login failed');
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = const Unauthenticated();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
