import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/fcm_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive offline cache
  await Hive.initFlutter();
  await Hive.openBox<String>(AppConstants.triageBox);
  await Hive.openBox<String>(AppConstants.settingsBox);

  // Warm JWT cache once so interceptor never hits Keystore per-request.
  await preloadToken();

  // Firebase / FCM (graceful fallback if not configured)
  await FcmService.initialize();

  runApp(const ProviderScope(child: HospitalTriajeApp()));
}

class HospitalTriajeApp extends ConsumerWidget {
  const HospitalTriajeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'HospitalTriaje',
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      locale: const Locale('es'),
      debugShowCheckedModeBanner: false,
    );
  }
}
