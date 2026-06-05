import 'package:flutter/material.dart';

class FacilityPostShiftScreen extends StatelessWidget {
  const FacilityPostShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pubblica Turno')),
      // TODO(step-5): form with fields: data/ora inizio-fine, ruolo richiesto,
      // note aggiuntive. On submit → insert row in shifts table (status = 'published').
      // TODO(business): pricing/compensation fields depend on business model decisions.
      body: const Center(
        child: Text('Form pubblicazione turno — implementato nello Step 5'),
      ),
    );
  }
}
