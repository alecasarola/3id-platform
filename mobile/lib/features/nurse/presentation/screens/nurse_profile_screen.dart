import 'package:flutter/material.dart';

class NurseProfileScreen extends StatelessWidget {
  const NurseProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo Infermiere')),
      // TODO(step-4): load/edit nurse profile, qualifiche, documenti from Supabase
      body: const Center(
        child: Text('Profilo — implementato nello Step 4'),
      ),
    );
  }
}
