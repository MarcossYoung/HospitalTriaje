import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../tips_data.dart';

class EmergencyTipsScreen extends StatelessWidget {
  const EmergencyTipsScreen({
    super.key,
    required this.category,
    required this.triageLevel,
    this.result,
  });

  final String category;
  final int triageLevel;
  final Map<String, dynamic>? result;

  @override
  Widget build(BuildContext context) {
    final tips = getTips(category);
    final color = TriageColors.forLevel(triageLevel);

    return Scaffold(
      backgroundColor: color.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: const Text('¡Atención Inmediata!'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert header
            Card(
              color: color.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: color, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tips.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
                          ),
                          Text(
                            'Nivel $triageLevel — Siga estas instrucciones inmediatamente',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (tips.callEmergency) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:911')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.phone),
                label: const Text('LLAMAR AL 911 AHORA', style: TextStyle(fontSize: 18)),
              ),
            ],

            const SizedBox(height: 24),

            // DO section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Qué HACER', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...tips.dos.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // DON'T section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Qué NO HACER', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...tips.donts.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✗ ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/hospitals'),
              icon: const Icon(Icons.local_hospital),
              label: const Text('Ver hospitales cercanos'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/triage/result', extra: result ?? {}),
              icon: const Icon(Icons.assessment),
              label: const Text('Ver resultado de triaje'),
            ),
          ],
        ),
      ),
    );
  }
}
