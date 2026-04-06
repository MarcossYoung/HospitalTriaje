import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final level = result['level'] as int;
    final label = result['label'] as String;
    final maxWait = result['max_wait_minutes'] as int;
    final category = result['complaint_category'] as String;
    final color = TriageColors.forLevel(level);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del triaje')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: color.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color,
                      child: Text(
                        '$level',
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(label, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      maxWait == 0 ? 'Atención inmediata' : 'Tiempo máximo de espera: $maxWait min',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('Categoría: $category', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(
                '/hospitals',
                extra: {'level': level, 'category': category},
              ),
              icon: const Icon(Icons.local_hospital),
              label: const Text('Ver hospitales cercanos'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/map'),
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/triage'),
              child: const Text('Nueva evaluación'),
            ),
          ],
        ),
      ),
    );
  }
}
