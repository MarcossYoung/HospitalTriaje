import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

final _evaluationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) return [];
  final dio = ref.watch(dioProvider);
  final resp = await dio.get(
    '/patients/me/evaluations',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  return (resp.data as List).cast<Map<String, dynamic>>();
});

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_evaluationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis evaluaciones')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Error al cargar evaluaciones'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(_evaluationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (evals) {
          if (evals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin evaluaciones registradas',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Las evaluaciones se guardan solo cuando realizás el triaje con la sesión iniciada.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/triage'),
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Ir al triaje'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: evals.length,
            itemBuilder: (ctx, i) => _EvaluationCard(data: evals[i]),
          );
        },
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final level = data['level'] as int;
    final category = data['complaint_category'] as String;
    final maxWait = data['max_wait_minutes'] as int;
    final createdAt = DateTime.tryParse(data['created_at'] as String);
    final color = TriageColors.forLevel(level);

    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}  '
            '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '$level',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          maxWait == 0
              ? 'Atención inmediata · $dateStr'
              : 'Espera máx. $maxWait min · $dateStr',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _levelLabel(level),
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
    );
  }

  String _levelLabel(int level) {
    const labels = {
      1: 'Inmediato',
      2: 'Muy urgente',
      3: 'Urgente',
      4: 'Menos urgente',
      5: 'No urgente',
    };
    return labels[level] ?? 'Nivel $level';
  }
}
