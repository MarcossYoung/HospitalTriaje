import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../providers/hospitals_provider.dart';
import '../models/hospital_model.dart';

class HospitalsListScreen extends ConsumerStatefulWidget {
  const HospitalsListScreen({super.key});

  @override
  ConsumerState<HospitalsListScreen> createState() => _HospitalsListScreenState();
}

class _HospitalsListScreenState extends ConsumerState<HospitalsListScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to SSE updates
    ref.listenManual(sseProvider, (_, event) {
      event.whenData((data) {
        ref.read(hospitalsProvider.notifier).applySSEUpdate(data);
      });
    });
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    double lat = 19.4326;
    double lng = -99.1332;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    await ref.read(hospitalsProvider.notifier).loadNearby(lat: lat, lng: lng);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitales cercanos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHospitals,
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(HospitalsState state) {
    if (state.loading && state.hospitals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadHospitals, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (state.hospitals.isEmpty) {
      return const Center(child: Text('No se encontraron hospitales'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.hospitals.length,
      itemBuilder: (ctx, i) => _HospitalCard(hospital: state.hospitals[i]),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});
  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
        title: Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(hospital.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
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
              ],
            ),
          ],
        ),
        onTap: () => context.push('/hospitals/${hospital.id}'),
      ),
    );
  }
}
