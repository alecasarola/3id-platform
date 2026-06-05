import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/router/app_router.dart';

class FacilityShellScreen extends StatelessWidget {
  const FacilityShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'I Miei Turni',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Pubblica',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Struttura',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoute.facilityShifts);
      case 1:
        context.go(AppRoute.facilityPostShift);
      case 2:
        context.go(AppRoute.facilityProfile);
    }
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/facility/post-shift')) return 1;
    if (path.startsWith('/facility/profile')) return 2;
    return 0;
  }
}
