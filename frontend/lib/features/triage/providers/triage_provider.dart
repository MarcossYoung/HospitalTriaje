import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class TriageState {
  final Map<String, dynamic>? tree;
  final List<Map<String, dynamic>> answers;
  final String? currentNodeId;
  final Map<String, dynamic>? result;
  final bool loading;
  final bool offline;
  final String? error;

  const TriageState({
    this.tree,
    this.answers = const [],
    this.currentNodeId,
    this.result,
    this.loading = false,
    this.offline = false,
    this.error,
  });

  TriageState copyWith({
    Map<String, dynamic>? tree,
    List<Map<String, dynamic>>? answers,
    String? currentNodeId,
    Map<String, dynamic>? result,
    bool? loading,
    bool? offline,
    String? error,
  }) =>
      TriageState(
        tree: tree ?? this.tree,
        answers: answers ?? this.answers,
        currentNodeId: currentNodeId ?? this.currentNodeId,
        result: result ?? this.result,
        loading: loading ?? this.loading,
        offline: offline ?? this.offline,
        error: error,
      );

  Map<String, dynamic>? get currentNode {
    if (tree == null || currentNodeId == null) return null;
    return (tree!['nodes'] as Map<String, dynamic>)[currentNodeId];
  }

  bool get isLeaf => currentNode != null && currentNode!.containsKey('triage_level');
}

class TriageNotifier extends StateNotifier<TriageState> {
  TriageNotifier(this._dio) : super(const TriageState());

  final Dio _dio;

  Future<void> loadTree() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _dio.get('/triage/questions');
      final tree = resp.data as Map<String, dynamic>;
      _cacheTree(tree);
      final root = tree['root'] as String;
      state = state.copyWith(
        tree: tree,
        currentNodeId: root,
        answers: [],
        result: null,
        loading: false,
        offline: false,
      );
    } catch (_) {
      final cached = _loadCachedTree();
      if (cached != null) {
        final root = cached['root'] as String;
        state = state.copyWith(
          tree: cached,
          currentNodeId: root,
          answers: [],
          result: null,
          loading: false,
          offline: true,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: 'Sin conexión con el servidor (${AppConstants.apiBaseUrl}) y sin caché disponible',
        );
      }
    }
  }

  void selectAnswer(int answerIndex) {
    final nodeId = state.currentNodeId;
    if (nodeId == null || state.tree == null) return;

    final node = state.currentNode;
    if (node == null) return;

    final newAnswers = [...state.answers, {'node_id': nodeId, 'answer_index': answerIndex}];
    final options = node['options'] as List<dynamic>;
    final nextId = options[answerIndex]['next_node_id'] as String;

    state = state.copyWith(answers: newAnswers, currentNodeId: nextId);
  }

  Future<Map<String, dynamic>?> evaluate() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _dio.post('/triage/evaluate', data: {'answers': state.answers});
      final result = resp.data as Map<String, dynamic>;
      state = state.copyWith(result: result, loading: false);
      return result;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Error al evaluar');
      return null;
    }
  }

  void reset() {
    if (state.tree != null) {
      state = state.copyWith(
        answers: [],
        currentNodeId: state.tree!['root'] as String,
        result: null,
        error: null,
      );
    }
  }

  void _cacheTree(Map<String, dynamic> tree) {
    final box = Hive.box<String>(AppConstants.triageBox);
    box.put(AppConstants.triageTreeHiveKey, jsonEncode(tree));
  }

  Map<String, dynamic>? _loadCachedTree() {
    final box = Hive.box<String>(AppConstants.triageBox);
    final raw = box.get(AppConstants.triageTreeHiveKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

final triageProvider = StateNotifierProvider<TriageNotifier, TriageState>((ref) {
  return TriageNotifier(ref.watch(dioProvider));
});
