import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    // Android emulator routes localhost to itself — use host loopback alias
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static const jwtStorageKey = 'hospital_triaje_jwt';
  static const triageTreeHiveKey = 'triage_question_tree';
  static const emergencyTipsHiveKey = 'emergency_tips';

  // Hive box names
  static const triageBox = 'triageBox';
  static const settingsBox = 'settingsBox';

  static String hospitalApiTokenKey(int id) => 'hospital_api_token_$id';
}
