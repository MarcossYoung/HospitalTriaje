import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/evaluations_screen.dart';
import '../../features/emergency/screens/emergency_tips_screen.dart';
import '../../features/hospitals/screens/hospital_admin_screen.dart';
import '../../features/hospitals/screens/hospital_detail_screen.dart';
import '../../features/hospitals/screens/hospitals_list_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/triage/screens/triage_screen.dart';
import '../../features/triage/screens/triage_result_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/triage',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/triage',
            builder: (context, state) => const TriageScreen(),
            routes: [
              GoRoute(
                path: 'result',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  if (extra == null) return const TriageScreen();
                  return TriageResultScreen(result: extra);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/hospitals',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return HospitalsListScreen(
                triageLevel: extra?['level'] as int?,
                triageCategory: extra?['category'] as String?,
              );
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => HospitalDetailScreen(
                  hospitalId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/hospitals/:id/admin',
            builder: (context, state) => HospitalAdminScreen(
              hospitalId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/evaluations',
            builder: (context, state) => const EvaluationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/emergency/:category',
        builder: (context, state) => EmergencyTipsScreen(
          category: state.pathParameters['category']!,
          triageLevel: int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1,
          result: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
});
