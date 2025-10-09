import 'package:flutter/material.dart';
import 'package:runsafe/screens/privacy_policy_screen.dart';
import 'package:runsafe/utils/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.run_circle_outlined,
                size: 100, color: AppColors.emerald),
            const SizedBox(height: 24),
            Text(
              'Bem-vindo ao RunSafe!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Mapeie suas rotas de corrida com alertas de segurança e corra com mais tranquilidade.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen()),
                );
              },
              child: const Text('Vamos Começar'),
            )
          ],
        ),
      ),
    );
  }
}