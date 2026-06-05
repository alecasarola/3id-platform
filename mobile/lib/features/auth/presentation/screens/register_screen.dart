import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/router/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // TODO(step-2): replace with FormKey, TextEditingControllers, real validation
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              Text(
                'Tipo di account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Role selector — value saved to Supabase profile in Step 2
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'nurse',
                    label: Text('Infermiere'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                  ButtonSegment(
                    value: 'facility',
                    label: Text('Struttura'),
                    icon: Icon(Icons.business_outlined),
                  ),
                ],
                selected: <String>{if (_selectedRole != null) _selectedRole!},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedRole = selection.isEmpty ? null : selection.first;
                  });
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        // TODO(step-2): call Supabase signUp, save role to profiles table
                        if (_selectedRole == 'nurse') {
                          context.go(AppRoute.nurseShifts);
                        } else {
                          context.go(AppRoute.facilityShifts);
                        }
                      },
                child: const Text('Crea account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
