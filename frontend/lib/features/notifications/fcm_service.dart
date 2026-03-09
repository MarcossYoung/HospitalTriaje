import 'package:flutter/foundation.dart';

class FcmService {
  static Future<void> initialize() async {
    try {
      // Firebase initialization would go here.
      // In a real setup: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Then: FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
      // For now, we skip silently if Firebase is not configured (dev mode).
      if (kDebugMode) {
        debugPrint('[FcmService] Firebase not configured — push notifications disabled in debug');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FcmService] Init failed: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      // return await FirebaseMessaging.instance.getToken();
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> requestPermission() async {
    try {
      // final settings = await FirebaseMessaging.instance.requestPermission();
      // handle settings.authorizationStatus
    } catch (_) {}
  }
}
