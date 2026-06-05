import 'package:flutter/material.dart';
import 'package:healthcare_marketplace/shared/widgets/empty_state_widget.dart';

class NurseShiftsScreen extends StatelessWidget {
  const NurseShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Turni Disponibili')),
      // TODO(step-4): read published shifts from Supabase and render list
      body: const EmptyStateWidget(
        message: 'Nessun turno disponibile al momento.',
        icon: Icons.work_outline,
      ),
    );
  }
}
