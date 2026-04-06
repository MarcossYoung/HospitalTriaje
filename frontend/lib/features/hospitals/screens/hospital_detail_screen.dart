import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../triage/providers/triage_provider.dart';
import '../models/hospital_model.dart';

class HospitalDetailScreen extends ConsumerStatefulWidget {
  const HospitalDetailScreen({super.key, required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends ConsumerState<HospitalDetailScreen> {
  HospitalModel? _hospital;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    try {
      final resp = await dio.get('/hospitals/${widget.hospitalId}');
      setState(() {
        _hospital = HospitalModel.fromJson(resp.data as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createReferral(int sessionId) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/hospitals/referrals', data: {
        'session_id': sessionId,
        'hospital_id': widget.hospitalId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ha sido derivado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No se pudo cargar la información del hospital'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final h = _hospital!;
    return Scaffold(
      appBar: AppBar(title: Text(h.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.place, text: h.address),
                  if (h.phone != null) _InfoRow(icon: Icons.phone, text: h.phone!),
                  if (h.waitTimeMin != null) _InfoRow(icon: Icons.timer, text: '${h.waitTimeMin} min de espera'),
                  if (h.availableBeds != null) _InfoRow(icon: Icons.bed, text: '${h.availableBeds} camas disponibles'),
                ],
              ),
            ),
          ),
          if (h.specialties.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Especialidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...h.specialties.map((s) => ListTile(
                          dense: true,
                          leading: Icon(
                            s.isAvailable ? Icons.check_circle : Icons.cancel,
                            color: s.isAvailable ? Colors.green : Colors.red,
                          ),
                          title: Text(s.nameEs),
                          subtitle: Text(s.isAvailable ? 'Disponible ahora' : 'No disponible'),
                        )),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final sessionId = ref.read(triageProvider).result?['session_id'] as int?;
              if (sessionId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completá un triaje primero para poder derivarte'),
                  ),
                );
                return;
              }
              _createReferral(sessionId);
            },
            icon: const Icon(Icons.send),
            label: const Text('Derivar a este hospital'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
