import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthcare_marketplace/router/app_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Healthcare\nMarketplace',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // TODO(step-2): wire to real Supabase auth, add form validation
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO(step-2): navigate to forgot-password screen
                  },
                  child: const Text('Password dimenticata?'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // TODO(step-2): call Supabase auth, then redirect by role.
                  // Placeholder: go directly to nurse home for manual testing.
                  context.go(AppRoute.nurseShifts);
                },
                child: const Text('Accedi'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRoute.register),
                child: const Text('Registrati'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
