import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';

class HospitalTokenNotifier extends StateNotifier<Map<int, String>> {
  HospitalTokenNotifier() : super({});

  static const _storage = FlutterSecureStorage();

  Future<void> loadToken(int hospitalId) async {
    final token = await _storage.read(key: AppConstants.hospitalApiTokenKey(hospitalId));
    if (token != null) {
      state = {...state, hospitalId: token};
    }
  }

  Future<void> saveToken(int hospitalId, String token) async {
    await _storage.write(key: AppConstants.hospitalApiTokenKey(hospitalId), value: token);
    state = {...state, hospitalId: token};
  }

  Future<void> clearToken(int hospitalId) async {
    await _storage.delete(key: AppConstants.hospitalApiTokenKey(hospitalId));
    final next = Map<int, String>.from(state);
    next.remove(hospitalId);
    state = next;
  }

  String? getToken(int hospitalId) => state[hospitalId];
}

final hospitalTokenProvider =
    StateNotifierProvider<HospitalTokenNotifier, Map<int, String>>((ref) {
  return HospitalTokenNotifier();
});
