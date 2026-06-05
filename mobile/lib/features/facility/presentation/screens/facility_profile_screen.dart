import 'package:flutter/material.dart';

class FacilityProfileScreen extends StatelessWidget {
  const FacilityProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo Struttura')),
      // TODO(step-5): load/edit facility profile from Supabase
      // Fields: ragione sociale, tipo struttura, indirizzo, referente
      body: const Center(
        child: Text('Profilo Struttura — implementato nello Step 5'),
      ),
    );
  }
}
