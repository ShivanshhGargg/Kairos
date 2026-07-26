import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_token_store.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(tokenStoreProvider),
    ref.watch(apiClientProvider),
  )..restore();
});

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
  });

  const AuthState.signedOut()
      : isAuthenticated = false,
        isLoading = false,
        error = null;

  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._tokenStore, this._apiClient)
      : super(const AuthState.signedOut());

  final SecureTokenStore _tokenStore;
  final ApiClient _apiClient;

  Future<void> restore() async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (!email.contains('@') || password.length < 4) {
      state = state.copyWith(
        isLoading: false,
        error: 'Use a valid email and password.',
      );
      return;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _saveAuthResponse(response.data);
      state = const AuthState(isAuthenticated: true, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign in failed. Check the backend auth endpoint.',
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (fullName.trim().isEmpty ||
        !email.contains('@') ||
        password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        error: 'Add your name, a valid email, and a stronger password.',
      );
      return;
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'fullName': fullName.trim(),
          'email': email,
          'password': password,
        },
      );
      await _saveAuthResponse(response.data);
      state = const AuthState(isAuthenticated: true, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Check the backend auth endpoint.',
      );
    }
  }

  Future<void> signOut() async {
    await _tokenStore.clear();
    state = const AuthState.signedOut();
  }

  Future<void> _saveAuthResponse(Object? source) async {
    final map = _mapOrNull(source);
    final payload = _mapOrNull(map?['data']) ?? map;
    final accessToken = payload?['accessToken']?.toString();
    final refreshToken = payload?['refreshToken']?.toString();
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw StateError(
          'Auth response did not include accessToken/refreshToken');
    }
    await _tokenStore.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Map<String, dynamic>? _mapOrNull(Object? source) {
    if (source is Map<String, dynamic>) return source;
    if (source is Map) {
      return source.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
