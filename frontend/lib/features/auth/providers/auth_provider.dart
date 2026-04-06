import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class AuthState {
  final String? token;
  final bool loading;
  final bool initializing;
  final String? error;

  const AuthState({this.token, this.loading = false, this.initializing = true, this.error});

  bool get isAuthenticated => token != null;

  AuthState copyWith({String? token, bool? loading, bool? initializing, String? error}) => AuthState(
        token: token ?? this.token,
        loading: loading ?? this.loading,
        initializing: initializing ?? this.initializing,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._dio) : super(const AuthState()) {
    _loadToken();
  }

  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn();

  Future<void> _loadToken() async {
    final token = await _storage.read(key: AppConstants.jwtStorageKey);
    state = AuthState(token: token, initializing: false);
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: AppConstants.jwtStorageKey, value: token);
    state = AuthState(token: token, initializing: false);
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _dio.post('/auth/register', data: {'email': email, 'password': password});
      await _saveToken(resp.data['access_token'] as String);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      await _saveToken(resp.data['access_token'] as String);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(loading: false);
        return false;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('No ID token');
      final resp = await _dio.post('/auth/google', data: {'id_token': idToken});
      await _saveToken(resp.data['access_token'] as String);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: _extractError(e));
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.jwtStorageKey);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    state = const AuthState(initializing: false);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) return data['detail'].toString();
    return 'Error de red';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider));
});
