import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

const _storage = FlutterSecureStorage();

// In-memory token cache — populated once at startup via [preloadToken].
// Avoids hitting Android Keystore on every request (100–500 ms per read).
String? _cachedToken;
bool _tokenLoaded = false;

/// Call once from main() before runApp to warm the token cache.
Future<void> preloadToken() async {
  _cachedToken = await _storage.read(key: AppConstants.jwtStorageKey);
  _tokenLoaded = true;
}

/// Update the in-memory cache and persist to secure storage.
/// Call this after login/logout instead of writing storage directly.
Future<void> setToken(String? token) async {
  _cachedToken = token;
  _tokenLoaded = true;
  if (token != null) {
    await _storage.write(key: AppConstants.jwtStorageKey, value: token);
  } else {
    await _storage.delete(key: AppConstants.jwtStorageKey);
  }
}

Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Read from memory cache; fall back to storage only on first call.
        if (!_tokenLoaded) {
          _cachedToken = await _storage.read(key: AppConstants.jwtStorageKey);
          _tokenLoaded = true;
        }
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) {
        handler.next(error);
      },
    ),
  );

  return dio;
}

final dioProvider = Provider<Dio>((ref) => buildDio());
