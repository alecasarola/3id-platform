import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/router/app_router.dart';
import 'package:healthcare_marketplace/shared/widgets/empty_state_widget.dart';

class FacilityShiftsScreen extends StatelessWidget {
  const FacilityShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I Miei Turni')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoute.facilityPostShift),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo turno'),
      ),
      // TODO(step-5): read facility's shifts from Supabase and render list
      body: const EmptyStateWidget(
        message: 'Nessun turno pubblicato ancora.\nCrea il tuo primo turno.',
        icon: Icons.work_outline,
        actionLabel: null,
      ),
    );
  }
}
