import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../models/hospital_model.dart';
import '../models/on_call_doctor_model.dart';
import '../models/obra_social_model.dart';
import '../providers/admin_provider.dart';
import '../providers/hospital_token_provider.dart';

final _hospitalDetailProvider =
    FutureProvider.autoDispose.family<HospitalModel, int>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/hospitals/$id');
  return HospitalModel.fromJson(resp.data as Map<String, dynamic>);
});

class HospitalAdminScreen extends ConsumerStatefulWidget {
  const HospitalAdminScreen({super.key, required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<HospitalAdminScreen> createState() => _HospitalAdminScreenState();
}

class _HospitalAdminScreenState extends ConsumerState<HospitalAdminScreen> {
  bool _tokenVerified = false;

  @override
  void initState() {
    super.initState();
    _tryLoadSavedToken();
  }

  Future<void> _tryLoadSavedToken() async {
    await ref.read(hospitalTokenProvider.notifier).loadToken(widget.hospitalId);
    final token = ref.read(hospitalTokenProvider)[widget.hospitalId];
    if (token != null && mounted) {
      setState(() => _tokenVerified = true);
    }
  }

  void _onTokenSaved() {
    setState(() => _tokenVerified = true);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the token map so the UI reacts when the token is cleared from _AdminBody
    final tokens = ref.watch(hospitalTokenProvider);
    final hasToken = _tokenVerified && tokens.containsKey(widget.hospitalId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar'),
        actions: [
          if (hasToken)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await ref.read(hospitalTokenProvider.notifier).clearToken(widget.hospitalId);
                setState(() => _tokenVerified = false);
              },
            ),
        ],
      ),
      body: hasToken
          ? _AdminBody(hospitalId: widget.hospitalId)
          : _TokenEntryDialog(
              hospitalId: widget.hospitalId,
              onTokenSaved: _onTokenSaved,
            ),
    );
  }
}

// ─── Token entry ──────────────────────────────────────────────────────────────

class _TokenEntryDialog extends ConsumerStatefulWidget {
  const _TokenEntryDialog({required this.hospitalId, required this.onTokenSaved});
  final int hospitalId;
  final VoidCallback onTokenSaved;

  @override
  ConsumerState<_TokenEntryDialog> createState() => _TokenEntryDialogState();
}

class _TokenEntryDialogState extends ConsumerState<_TokenEntryDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    final token = _controller.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Validate token against a protected endpoint.
      // DELETE /on-call/0 requires auth: 403 = bad token, 404 = good token (doctor not found).
      final dio = ref.read(dioProvider);
      await dio.delete(
        '/hospitals/${widget.hospitalId}/on-call/0',
        options: Options(headers: {'X-API-Token': token}),
      );
      // 204 would mean it somehow deleted — still means token is valid
      await ref.read(hospitalTokenProvider.notifier).saveToken(widget.hospitalId, token);
      if (mounted) widget.onTokenSaved();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) {
        // Token is valid, doctor ID 0 just doesn't exist — that's expected
        await ref.read(hospitalTokenProvider.notifier).saveToken(widget.hospitalId, token);
        if (mounted) widget.onTokenSaved();
      } else {
        if (mounted) setState(() {
          _error = code == 403 ? 'Token inválido' : 'Error de conexión';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Error inesperado';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingrese el token de acceso del hospital',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Token API',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ─── Admin body ───────────────────────────────────────────────────────────────

class _AdminBody extends ConsumerStatefulWidget {
  const _AdminBody({required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<_AdminBody> createState() => _AdminBodyState();
}

class _AdminBodyState extends ConsumerState<_AdminBody> {
  final _bedsController = TextEditingController();
  bool _bedsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_hospitalDetailProvider(widget.hospitalId)).whenData((h) {
        if (!_bedsInitialized && h.availableBeds != null) {
          setState(() {
            _bedsInitialized = true;
            _bedsController.text = '${h.availableBeds}';
          });
        }
      });
    });
  }

  Future<void> _saveBeds() async {
    final beds = int.tryParse(_bedsController.text.trim());
    if (beds == null) return;
    final token = ref.read(hospitalTokenProvider)[widget.hospitalId];
    if (token == null) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/hospitals/${widget.hospitalId}/beds',
        data: {'available_beds': beds},
        options: Options(headers: {'X-API-Token': token}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camas actualizadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _walkIn() async {
    final token = ref.read(hospitalTokenProvider)[widget.hospitalId];
    if (token == null) return;
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(
        '/hospitals/${widget.hospitalId}/walk-in',
        options: Options(headers: {'X-API-Token': token}),
      );
      final newWait = resp.data['wait_time_min'] as int;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tiempo de espera actualizado: $newWait min')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileSection(hospitalId: widget.hospitalId),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Estado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _bedsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Camas disponibles',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saveBeds,
                child: const Text('Guardar camas'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _walkIn,
                icon: const Icon(Icons.person_add),
                label: const Text('Paciente sin turno (+10 min)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _OnCallSection(hospitalId: widget.hospitalId),
        const SizedBox(height: 16),
        _ObrasSocialesSection(hospitalId: widget.hospitalId),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Token',
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(hospitalTokenProvider.notifier)
                  .clearToken(widget.hospitalId);
            },
            icon: const Icon(Icons.key),
            label: const Text('Cambiar token API'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bedsController.dispose();
    super.dispose();
  }
}

// ─── On-call section ──────────────────────────────────────────────────────────

class _OnCallSection extends ConsumerWidget {
  const _OnCallSection({required this.hospitalId});
  final int hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(onCallDoctorsProvider(hospitalId));
    return _SectionCard(
      title: 'Médicos de guardia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          async.when(
            data: (doctors) => Column(
              children: [
                ...doctors.map((d) => _DoctorTile(
                      doctor: d,
                      onDelete: () => ref
                          .read(onCallDoctorsProvider(hospitalId).notifier)
                          .removeDoctor(d.id),
                    )),
                if (doctors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin médicos de guardia registrados'),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddDoctorDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Agregar médico'),
          ),
        ],
      ),
    );
  }

  void _showAddDoctorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddDoctorDialog(hospitalId: hospitalId),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor, required this.onDelete});
  final OnCallDoctorModel doctor;
  final VoidCallback onDelete;

  static final _fmt = DateFormat('dd/MM HH:mm');

  @override
  Widget build(BuildContext context) {
    final fmt = _fmt;
    final initials = doctor.doctorName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return ListTile(
      leading: CircleAvatar(child: Text(initials)),
      title: Text(doctor.doctorName),
      subtitle: Text(
        '${doctor.specialtyName ?? 'Sin especialidad'} · ${fmt.format(doctor.shiftStart.toLocal())} – ${fmt.format(doctor.shiftEnd.toLocal())}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

class _AddDoctorDialog extends ConsumerStatefulWidget {
  const _AddDoctorDialog({required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends ConsumerState<_AddDoctorDialog> {
  final _nameController = TextEditingController();
  int? _selectedSpecialtyId;
  DateTime? _shiftStart;
  DateTime? _shiftEnd;
  bool _loading = false;

  static final _fmt = DateFormat('dd/MM HH:mm');

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _shiftStart = dt;
      } else {
        _shiftEnd = dt;
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _shiftStart == null || _shiftEnd == null) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(onCallDoctorsProvider(widget.hospitalId).notifier)
          .addDoctor(
            doctorName: name,
            specialtyId: _selectedSpecialtyId,
            shiftStart: _shiftStart!,
            shiftEnd: _shiftEnd!,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _fmt;
    final specialtiesAsync = ref.watch(hospitalSpecialtiesProvider(widget.hospitalId));
    return AlertDialog(
      title: const Text('Agregar médico de guardia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre del médico'),
          ),
          const SizedBox(height: 12),
          specialtiesAsync.when(
            data: (specialties) => DropdownButtonFormField<int?>(
              value: _selectedSpecialtyId,
              decoration: const InputDecoration(labelText: 'Especialidad'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin especialidad'),
                ),
                ...specialties.map((s) => DropdownMenuItem<int?>(
                      value: s.id,
                      child: Text(s.nameEs),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedSpecialtyId = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error cargando especialidades'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_shiftStart == null
                ? 'Inicio de turno'
                : 'Inicio: ${fmt.format(_shiftStart!)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickDateTime(true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_shiftEnd == null
                ? 'Fin de turno'
                : 'Fin: ${fmt.format(_shiftEnd!)}'),
            trailing: const Icon(Icons.access_time),
            onTap: () => _pickDateTime(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// ─── Obras sociales section ───────────────────────────────────────────────────

class _ObrasSocialesSection extends ConsumerStatefulWidget {
  const _ObrasSocialesSection({required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<_ObrasSocialesSection> createState() => _ObrasSocialesSectionState();
}

class _ObrasSocialesSectionState extends ConsumerState<_ObrasSocialesSection> {
  Set<int> _selectedIds = {};
  final _searchNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Seed _selectedIds from the provider's current value if it is already
    // loaded (provider has no autoDispose, so cached data across navigations
    // won't trigger ref.listen below). addPostFrameCallback ensures ref.read
    // runs after the first frame when ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(hospitalObrasSocialesProvider(widget.hospitalId)).whenData((selected) {
        setState(() {
          _selectedIds = selected.map((s) => s.id).toSet();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(obrasSocialesProvider);

    // Sync _selectedIds whenever the provider emits new server data.
    // Do NOT also ref.watch the same provider — the double-subscription
    // (watch + listen) triggers two rebuild paths on the same state change
    // and can cause setState-during-build conflicts.
    ref.listen(hospitalObrasSocialesProvider(widget.hospitalId), (_, next) {
      next.whenData((selected) {
        setState(() {
          _selectedIds = selected.map((s) => s.id).toSet();
        });
      });
    });

    return _SectionCard(
      title: 'Obras Sociales',
      child: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (all) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _searchNotifier.value = v,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: _searchNotifier,
                builder: (context, search, _) {
                  final filtered = all
                      .where((os) =>
                          search.isEmpty ||
                          os.name.toLowerCase().contains(search.toLowerCase()))
                      .toList();
                  return Column(
                    children: filtered
                        .map((os) => CheckboxListTile(
                              value: _selectedIds.contains(os.id),
                              title: Text(os.name),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedIds = {..._selectedIds, os.id};
                                  } else {
                                    _selectedIds = _selectedIds
                                        .where((id) => id != os.id)
                                        .toSet();
                                  }
                                });
                              },
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(hospitalObrasSocialesProvider(widget.hospitalId).notifier)
                        .saveObrasSociales(_selectedIds.toList());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coberturas actualizadas')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Guardar coberturas'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Profile section ──────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection({required this.hospitalId});
  final int hospitalId;

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    // Seed controllers if the provider is already loaded (autoDispose means it
    // always starts fresh here, but guard anyway for resilience).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_hospitalDetailProvider(widget.hospitalId)).whenData((h) {
        if (!_editing) _populateControllers(h);
      });
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(HospitalModel h) {
    _addressCtrl.text = h.address;
    _phoneCtrl.text = h.phone ?? '';
  }

  Future<void> _save() async {
    final token = ref.read(hospitalTokenProvider)[widget.hospitalId];
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        '/hospitals/${widget.hospitalId}/info',
        data: {
          'address': _addressCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        },
        options: Options(headers: {'X-API-Token': token}),
      );
      ref.invalidate(_hospitalDetailProvider(widget.hospitalId));
      setState(() {
        _editing = false;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_hospitalDetailProvider(widget.hospitalId));

    // After a save, ref.invalidate triggers a fresh load → new AsyncData
    // transition → this listener fires → controllers re-populated.
    // ref.listen is safe here: Riverpod defers the callback to post-build,
    // avoiding setState-during-build. The addPostFrameCallback in initState
    // covers the initial load so the listener only needs to handle reloads.
    ref.listen(_hospitalDetailProvider(widget.hospitalId), (_, next) {
      next.whenData((h) {
        if (!_editing) _populateControllers(h);
      });
    });

    return _SectionCard(
      title: 'Perfil del hospital',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (h) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_editing ? Icons.close : Icons.edit),
                    tooltip: _editing ? 'Cancelar' : 'Editar',
                    onPressed: () => setState(() {
                      _editing = !_editing;
                      if (!_editing) _populateControllers(h);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                readOnly: !_editing,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                readOnly: !_editing,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
