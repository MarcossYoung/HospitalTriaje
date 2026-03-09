import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/hospital_model.dart';

// ─── Hospital list state ───────────────────────────────────────────────────

class HospitalsState {
  final List<HospitalModel> hospitals;
  final bool loading;
  final String? error;

  const HospitalsState({this.hospitals = const [], this.loading = false, this.error});
}

class HospitalsNotifier extends StateNotifier<HospitalsState> {
  HospitalsNotifier(this._dio) : super(const HospitalsState());

  final Dio _dio;

  Future<void> loadNearby({
    required double lat,
    required double lng,
    String? specialty,
    int? level,
  }) async {
    state = HospitalsState(hospitals: state.hospitals, loading: true);
    try {
      final params = <String, dynamic>{'lat': lat, 'lng': lng};
      if (specialty != null) params['specialty'] = specialty;
      if (level != null) params['level'] = level;

      final resp = await _dio.get('/hospitals/nearby', queryParameters: params);
      final list = (resp.data as List)
          .map((e) => HospitalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = HospitalsState(hospitals: list);
    } catch (e) {
      state = HospitalsState(hospitals: state.hospitals, error: e.toString());
    }
  }

  void applySSEUpdate(Map<String, dynamic> event) {
    final id = event['hospital_id'] as int;
    final wait = event['wait_time_min'] as int;
    final beds = event['available_beds'] as int;

    final updated = state.hospitals.map((h) {
      if (h.id == id) {
        return h.copyWith(waitTimeMin: wait, availableBeds: beds);
      }
      return h;
    }).toList();
    state = HospitalsState(hospitals: updated);
  }
}

final hospitalsProvider = StateNotifierProvider<HospitalsNotifier, HospitalsState>((ref) {
  return HospitalsNotifier(ref.watch(dioProvider));
});

// ─── SSE stream provider ───────────────────────────────────────────────────

final sseProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final dio = ref.watch(dioProvider);
  final controller = StreamController<Map<String, dynamic>>();

  // Use Dio's streaming capabilities for SSE
  _connectSSE(dio, controller);

  ref.onDispose(controller.close);
  return controller.stream;
});

Future<void> _connectSSE(
  Dio dio,
  StreamController<Map<String, dynamic>> controller,
) async {
  try {
    final resp = await dio.get<ResponseBody>(
      '/hospitals/stream',
      options: Options(responseType: ResponseType.stream),
    );
    final stream = resp.data!.stream;
    StringBuffer buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final raw = buffer.toString();
      final lines = raw.split('\n');
      // Keep partial last line in buffer
      buffer.clear();
      if (!raw.endsWith('\n')) {
        buffer.write(lines.removeLast());
      }
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final json = line.substring(6).trim();
          if (json.isNotEmpty) {
            try {
              final event = jsonDecode(json) as Map<String, dynamic>;
              controller.add(event);
            } catch (_) {}
          }
        }
      }
    }
  } catch (_) {
    // Silently reconnect after error — can add exponential backoff
    await Future.delayed(const Duration(seconds: 5));
    if (!controller.isClosed) _connectSSE(dio, controller);
  }
}
