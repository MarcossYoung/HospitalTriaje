import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/triage_provider.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';

class TriageScreen extends ConsumerStatefulWidget {
  const TriageScreen({super.key});

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(triageProvider.notifier).loadTree());
  }

  Future<void> _onAnswerSelected(int index) async {
    final notifier = ref.read(triageProvider.notifier);
    notifier.selectAnswer(index);

    final state = ref.read(triageProvider);
    if (state.isLeaf) {
      // Reached a leaf — evaluate via API
      final result = await notifier.evaluate();
      if (result != null && mounted) {
        final level = result['level'] as int;
        if (level <= 2) {
          context.push('/emergency/${result['complaint_category']}?level=$level', extra: result);
        } else {
          context.push('/triage/result', extra: result);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación de Triaje'),
        actions: [
          if (state.answers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(triageProvider.notifier).reset(),
              tooltip: 'Reiniciar',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (state.offline) const OfflineBanner(),
              Expanded(child: _buildBody(state)),
            ],
          ),
          if (state.loading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody(TriageState state) {
    if (state.loading && state.tree == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tree == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(triageProvider.notifier).loadTree(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.tree == null) {
      return const Center(child: Text('Cargando árbol de preguntas...'));
    }

    final node = state.currentNode;
    if (node == null) return const Center(child: Text('Error en el árbol'));

    // Progress indicator
    final stepCount = state.answers.length;

    return Column(
      children: [
        LinearProgressIndicator(value: stepCount / 6.0),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta ${stepCount + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  node['question_es'] as String,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                ..._buildOptions(node),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions(Map<String, dynamic> node) {
    final options = node['options'] as List<dynamic>;
    return options.asMap().entries.map((entry) {
      final i = entry.key;
      final option = entry.value as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _onAnswerSelected(i),
          child: Text(
            option['label_es'] as String,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      );
    }).toList();
  }
}
