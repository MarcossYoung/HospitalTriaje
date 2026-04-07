import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/hospitals_provider.dart';
import '../models/hospital_model.dart';

class HospitalsListScreen extends ConsumerStatefulWidget {
  const HospitalsListScreen({super.key, this.triageLevel, this.triageCategory});

  final int? triageLevel;
  final String? triageCategory;

  @override
  ConsumerState<HospitalsListScreen> createState() => _HospitalsListScreenState();
}

class _HospitalsListScreenState extends ConsumerState<HospitalsListScreen> {
  ProviderSubscription? _sseSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to SSE updates
    _sseSub = ref.listenManual(sseProvider, (_, event) {
      event.whenData((data) {
        ref.read(hospitalsProvider.notifier).applySSEUpdate(data);
      });
    });
    _loadHospitals();
  }

  @override
  void dispose() {
    _sseSub?.close();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    double lat = -34.6037;
    double lng = -58.3816;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 8));
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {
      // fall through to default Buenos Aires coords
    }

    if (!mounted) return;
    await ref.read(hospitalsProvider.notifier).loadNearby(
      lat: lat,
      lng: lng,
      level: widget.triageLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitales cercanos'),
        actions: [
          Semantics(
            label: 'Actualizar lista de hospitales',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHospitals,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.triageLevel != null) _UrgencyBanner(level: widget.triageLevel!, category: widget.triageCategory),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(HospitalsState state) {
    if (state.loading && state.hospitals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: AppSpacing.lg),
            Text(state.error!),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Reintentar cargar hospitales cercanos',
              button: true,
              child: ElevatedButton(
                onPressed: _loadHospitals,
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }
    if (state.hospitals.isEmpty) {
      return const Center(child: Text('No se encontraron hospitales'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.hospitals.length,
      itemBuilder: (ctx, i) => _HospitalCard(hospital: state.hospitals[i]),
    );
  }
}

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner({required this.level, this.category});
  final int level;
  final String? category;

  static const _labels = {
    1: 'Inmediato',
    2: 'Muy urgente',
    3: 'Urgente',
    4: 'Menos urgente',
    5: 'No urgente',
  };

  @override
  Widget build(BuildContext context) {
    final color = TriageColors.forLevel(level);
    final label = _labels[level] ?? 'Nivel $level';
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizing.avatarRadiusSm,
            backgroundColor: color,
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              category != null ? '$label · $category' : label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});
  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hospital: ${hospital.name}. Toque para ver detalles.',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: () => context.push('/hospitals/${hospital.id}'),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizing.minTapTarget),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
              title: Text(
                hospital.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  Text(hospital.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      if (hospital.waitTimeMin != null)
                        Chip(
                          label: Text('${hospital.waitTimeMin} min'),
                          avatar: const Icon(Icons.timer, size: 16),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (hospital.distanceKm != null)
                        Chip(
                          label: Text('${hospital.distanceKm!.toStringAsFixed(1)} km'),
                          avatar: const Icon(Icons.place, size: 16),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (hospital.availableBeds != null)
                        Chip(
                          label: Text('${hospital.availableBeds} camas'),
                          avatar: const Icon(Icons.bed, size: 16),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (hospital.specialties.any((s) => s.isAvailable))
                        Chip(
                          label: const Text('guardia especializada'),
                          avatar: const Icon(Icons.medical_services, size: 16),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
