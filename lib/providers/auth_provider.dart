import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spotify_auth_service.dart';

final authServiceProvider = Provider<SpotifyAuthService>((ref) {
  return SpotifyAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SpotifyAuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  Future<void> loadSavedTokens() async {
    await _service.loadSavedTokens();
    state = state.copyWith(isAuthenticated: _service.isAuthenticated);
  }

  Future<void> login({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.authenticate(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
      );
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(isAuthenticated: false);
  }

  String? get accessToken => _service.accessToken;

  Future<void> refreshIfNeeded({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      await _service.refreshIfNeeded(
        clientId: clientId,
        clientSecret: clientSecret,
      );
      state = state.copyWith(isAuthenticated: _service.isAuthenticated);
    } catch (_) {}
  }
}
