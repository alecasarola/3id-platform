import 'package:flutter/material.dart';
import 'package:healthcare_marketplace/shared/widgets/empty_state_widget.dart';

class NurseApplicationsScreen extends StatelessWidget {
  const NurseApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Le Mie Candidature')),
      // TODO(step-4): read nurse's applications from Supabase and render list
      body: const EmptyStateWidget(
        message: 'Nessuna candidatura inviata ancora.',
        icon: Icons.assignment_outlined,
      ),
    );
  }
}
