import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../hospitals/models/hospital_model.dart';
import '../../hospitals/providers/hospitals_provider.dart';
import '../../../core/theme/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _userLocation = const LatLng(19.4326, -99.1332);
  Set<Marker> _markers = {};
  HospitalModel? _selectedHospital;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    // Listen to SSE for live updates
    ref.listenManual(sseProvider, (_, event) {
      event.whenData((data) {
        ref.read(hospitalsProvider.notifier).applySSEUpdate(data);
        _updateMarkers(ref.read(hospitalsProvider).hospitals);
      });
    });
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      await ref.read(hospitalsProvider.notifier).loadNearby(
            lat: pos.latitude,
            lng: pos.longitude,
          );
    } catch (_) {
      await ref.read(hospitalsProvider.notifier).loadNearby(
            lat: _userLocation.latitude,
            lng: _userLocation.longitude,
          );
    }
    _updateMarkers(ref.read(hospitalsProvider).hospitals);
  }

  void _updateMarkers(List<HospitalModel> hospitals) {
    final markers = hospitals.map((h) {
      return Marker(
        markerId: MarkerId('h${h.id}'),
        position: LatLng(h.lat, h.lng),
        infoWindow: InfoWindow(
          title: h.name,
          snippet: h.waitTimeMin != null ? '${h.waitTimeMin} min de espera' : null,
        ),
        onTap: () => setState(() => _selectedHospital = h),
      );
    }).toSet();
    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de hospitales')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _userLocation, zoom: 12),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
          ),
          if (state.loading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: Card(child: Padding(padding: EdgeInsets.all(8), child: Text('Cargando hospitales...')))),
            ),
          if (_selectedHospital != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _HospitalBottomSheet(
                hospital: _selectedHospital!,
                onClose: () => setState(() => _selectedHospital = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _HospitalBottomSheet extends StatelessWidget {
  const _HospitalBottomSheet({required this.hospital, required this.onClose});
  final HospitalModel hospital;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
            Text(hospital.address, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (hospital.waitTimeMin != null)
                  Chip(label: Text('${hospital.waitTimeMin} min'), avatar: const Icon(Icons.timer, size: 16)),
                if (hospital.distanceKm != null)
                  Chip(label: Text('${hospital.distanceKm!.toStringAsFixed(1)} km'), avatar: const Icon(Icons.place, size: 16)),
                if (hospital.availableBeds != null)
                  Chip(label: Text('${hospital.availableBeds} camas'), avatar: const Icon(Icons.bed, size: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/hospitals/${hospital.id}'),
                    child: const Text('Ver detalle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
