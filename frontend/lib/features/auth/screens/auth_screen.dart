import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authProvider.notifier);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    bool ok;
    if (_isRegister) {
      ok = await notifier.register(email, pass);
    } else {
      ok = await notifier.login(email, pass);
    }
    if (ok && mounted) context.go('/triage');
  }

  Future<void> _googleSignIn() async {
    final ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (ok && mounted) context.go('/triage');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('HospitalTriaje')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegister ? 'Crear cuenta' : 'Iniciar sesión',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
              ),
            if (auth.error != null) const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading ? null : _submit,
              child: auth.loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isRegister ? 'Registrarse' : 'Iniciar sesión'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: auth.loading ? null : _googleSignIn,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continuar con Google'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/triage'),
              child: const Text('Continuar sin cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
