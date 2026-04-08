import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/triage_provider.dart';
import '../../../core/constants/design_tokens.dart';
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

  Future<void> _evaluateAndNavigate() async {
    final result = await ref.read(triageProvider.notifier).evaluate();
    if (result != null && mounted) {
      final level = result['level'] as int;
      if (level <= 2) {
        context.push('/emergency/${result['complaint_category']}?level=$level', extra: result);
      } else {
        context.push('/triage/result', extra: result);
      }
    }
  }

  Future<void> _onAnswerSelected(int index) async {
    final notifier = ref.read(triageProvider.notifier);
    notifier.selectAnswer(index);
    final state = ref.read(triageProvider);
    if (state.isLeaf && state.obraSocial != null) await _evaluateAndNavigate();
    // If isLeaf but obraSocial == null, _buildBody shows the obra social question
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        title: const Text('Evaluación de Triaje'),
        leading: state.answers.isNotEmpty && !state.isLeaf
            ? Semantics(
                label: 'Volver a la pregunta anterior',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => ref.read(triageProvider.notifier).goBack(),
                  tooltip: 'Pregunta anterior',
                ),
              )
            : null,
        actions: [
          if (state.answers.isNotEmpty)
            Semantics(
              label: 'Reiniciar evaluación',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(triageProvider.notifier).reset(),
                tooltip: 'Reiniciar',
              ),
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
            const SizedBox(height: AppSpacing.lg),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Reintentar cargar el árbol de triaje',
              button: true,
              child: ElevatedButton(
                onPressed: () => ref.read(triageProvider.notifier).loadTree(),
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }

    if (state.tree == null) {
      return const Center(child: Text('Cargando árbol de preguntas...'));
    }

    // Evaluation completed — user navigated back from result screen.
    if (state.result != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: AppSpacing.lg),
            const Text('Evaluación completada', style: TextStyle(fontSize: 18)),
            const SizedBox(height: AppSpacing.xxl),
            Semantics(
              label: 'Iniciar nueva evaluación de triaje',
              button: true,
              child: ElevatedButton(
                onPressed: () => ref.read(triageProvider.notifier).reset(),
                child: const Text('Nueva evaluación'),
              ),
            ),
          ],
        ),
      );
    }

    final node = state.currentNode;
    if (node == null) return const Center(child: Text('Error en el árbol'));

    // Obra social question shown after all medical questions are answered.
    if (state.isLeaf && state.obraSocial == null) {
      return _buildObraSocialQuestion(state.answers.length);
    }

    // Leaf node: evaluation is in progress or failed.
    if (state.isLeaf) {
      if (state.loading) return const SizedBox.shrink(); // Loading overlay handles UI.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orange),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'No se pudo obtener el resultado.\nVerifique su conexión e intente nuevamente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(
                label: 'Intentar obtener el resultado de triaje de nuevo',
                button: true,
                child: ElevatedButton(
                  onPressed: _evaluateAndNavigate,
                  child: const Text('Intentar de nuevo'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Progress indicator
    final stepCount = state.answers.length;

    return Column(
      children: [
        LinearProgressIndicator(value: (stepCount / 6.0).clamp(0.0, 1.0)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta ${stepCount + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  node['question_es'] as String,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                ..._buildOptions(node),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _obraSocialOptions = [
    'PAMI',
    'Prepaga o obra social privada (OSDE, Swiss Medical, Galeno, etc.)',
    'Obra social sindical o provincial (IOMA, etc.)',
    'Sin cobertura / particular',
  ];

  Widget _buildObraSocialQuestion(int stepCount) {
    return Column(
      children: [
        const LinearProgressIndicator(value: 1.0),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta ${stepCount + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '¿Qué cobertura médica tiene?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                ..._obraSocialOptions.map((label) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Semantics(
                    label: 'Opción de cobertura: $label',
                    button: true,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size.fromHeight(AppSizing.minTapTarget),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                      onPressed: () async {
                        ref.read(triageProvider.notifier).setObraSocial(label);
                        await _evaluateAndNavigate();
                      },
                      child: Text(label, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                )),
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
      final labelText = option['label_es'] as String;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          label: 'Opción de respuesta: $labelText',
          button: true,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(AppSizing.minTapTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            onPressed: () => _onAnswerSelected(i),
            child: Text(labelText, style: const TextStyle(fontSize: 15)),
          ),
        ),
      );
    }).toList();
  }
}
