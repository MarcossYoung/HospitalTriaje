import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/hospital_model.dart';
import '../models/on_call_doctor_model.dart';
import '../models/obra_social_model.dart';
import 'hospital_token_provider.dart';

class HospitalTokenMissingException implements Exception {
  const HospitalTokenMissingException(this.hospitalId);
  final int hospitalId;
  @override
  String toString() => 'Token no configurado para hospital $hospitalId';
}

// ─── On-call doctors ──────────────────────────────────────────────────────────

class OnCallDoctorsNotifier extends FamilyAsyncNotifier<List<OnCallDoctorModel>, int> {
  late int _hospitalId;

  @override
  Future<List<OnCallDoctorModel>> build(int hospitalId) async {
    _hospitalId = hospitalId;
    return _load();
  }

  Future<List<OnCallDoctorModel>> _load() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/hospitals/$_hospitalId/on-call');
    return (resp.data as List)
        .map((e) => OnCallDoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDoctor({
    required String doctorName,
    int? specialtyId,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    final token = ref.read(hospitalTokenProvider)[_hospitalId];
    if (token == null) throw HospitalTokenMissingException(_hospitalId);
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    try {
      await dio.post(
        '/hospitals/$_hospitalId/on-call',
        data: {
          'doctor_name': doctorName,
          'specialty_id': specialtyId,
          'shift_start': shiftStart.toUtc().toIso8601String(),
          'shift_end': shiftEnd.toUtc().toIso8601String(),
        },
        options: Options(headers: {'X-API-Token': token}),
      );
      state = AsyncData(await _load());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> removeDoctor(int doctorId) async {
    final token = ref.read(hospitalTokenProvider)[_hospitalId];
    if (token == null) throw HospitalTokenMissingException(_hospitalId);
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    try {
      await dio.delete(
        '/hospitals/$_hospitalId/on-call/$doctorId',
        options: Options(headers: {'X-API-Token': token}),
      );
      state = AsyncData(await _load());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final onCallDoctorsProvider =
    AsyncNotifierProviderFamily<OnCallDoctorsNotifier, List<OnCallDoctorModel>, int>(
  OnCallDoctorsNotifier.new,
);

// ─── Hospital specialties (for doctor dialog) ────────────────────────────────

final hospitalSpecialtiesProvider = FutureProvider.family<List<SpecialtyModel>, int>((ref, hospitalId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/hospitals/$hospitalId');
  final data = resp.data as Map<String, dynamic>;
  final specs = (data['specialties'] as List<dynamic>? ?? [])
      .map((e) => SpecialtyModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return specs;
});

// ─── Obras sociales (full list) ───────────────────────────────────────────────

final obrasSocialesProvider = FutureProvider<List<ObraSocialModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/hospitals/obras-sociales');
  return (resp.data as List)
      .map((e) => ObraSocialModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Hospital obras sociales (selection) ──────────────────────────────────────

class HospitalObrasSocialesNotifier
    extends FamilyAsyncNotifier<List<ObraSocialModel>, int> {
  late int _hospitalId;

  @override
  Future<List<ObraSocialModel>> build(int hospitalId) async {
    _hospitalId = hospitalId;
    return _load();
  }

  Future<List<ObraSocialModel>> _load() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/hospitals/$_hospitalId/obras-sociales');
    return (resp.data as List)
        .map((e) => ObraSocialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveObrasSociales(List<int> obraSocialIds) async {
    final token = ref.read(hospitalTokenProvider)[_hospitalId];
    if (token == null) throw HospitalTokenMissingException(_hospitalId);
    final dio = ref.read(dioProvider);
    // Set loading BEFORE any async work so the UI shows a spinner immediately.
    // Also wraps the PUT itself — if it fails, state goes to AsyncError instead
    // of silently staying on stale AsyncData.
    state = const AsyncLoading();
    try {
      await dio.put(
        '/hospitals/$_hospitalId/obras-sociales',
        data: {'obra_social_ids': obraSocialIds},
        options: Options(headers: {'X-API-Token': token}),
      );
      state = AsyncData(await _load());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final hospitalObrasSocialesProvider =
    AsyncNotifierProviderFamily<HospitalObrasSocialesNotifier, List<ObraSocialModel>, int>(
  HospitalObrasSocialesNotifier.new,
);
