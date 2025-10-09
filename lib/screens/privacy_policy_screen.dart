import 'package:flutter/material.dart';
import 'package:runsafe/screens/home_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade e Consentimento'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uso da Localização',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Para mapear suas rotas e fornecer alertas de segurança, o RunSafe precisa acessar a localização do seu dispositivo. Você pode negar essa permissão e inserir suas rotas manualmente.'),
                    const SizedBox(height: 24),
                    Text(
                      'LGPD e Seus Dados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Respeitamos a sua privacidade. Seus dados de localização são utilizados exclusivamente para as funcionalidades do aplicativo e não são compartilhados com terceiros sem o seu consentimento explícito. Você pode gerenciar suas permissões a qualquer momento nas configurações do seu dispositivo.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // No futuro, aqui será o local para pedir a permissão de localização
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Entendi e Concordo'),
            ),
          ],
        ),
      ),
    );
  }
}