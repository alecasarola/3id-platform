import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/router/app_router.dart';

class NurseShellScreen extends StatelessWidget {
  const NurseShellScreen({super.key, required this.child});

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
            label: 'Turni',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Candidature',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoute.nurseShifts);
      case 1:
        context.go(AppRoute.nurseApplications);
      case 2:
        context.go(AppRoute.nurseProfile);
    }
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/nurse/applications')) return 1;
    if (path.startsWith('/nurse/profile')) return 2;
    return 0;
  }
}
