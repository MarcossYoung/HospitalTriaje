import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  static int _locationToIndex(String location) {
    if (location.startsWith('/triage')) return 0;
    if (location.startsWith('/hospitals')) return 1;
    if (location.startsWith('/map')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _locationToIndex(location),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/triage');
            case 1:
              context.go('/hospitals');
            case 2:
              context.go('/map');
            case 3:
              context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.medical_services), label: 'Triaje'),
          NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Hospitales'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
