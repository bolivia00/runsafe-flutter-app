import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidade',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Última atualização: ${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: '1. Introdução'),
            const _SectionContent(
              content: 'RunSafe é comprometido com a proteção de sua privacidade. '
                  'Esta política de privacidade explica como coletamos, usamos e protegemos '
                  'suas informações pessoais.',
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: '2. Coleta de Dados'),
            const _SectionContent(
              content: 'Coletamos informações necessárias para operar o aplicativo, '
                  'incluindo dados de localização, informações de corridas e alertas de segurança.',
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: '3. Uso de Dados'),
            const _SectionContent(
              content: 'Seus dados são usados exclusivamente para melhorar sua experiência '
                  'e fornecer recursos de segurança aprimorados.',
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: '4. Segurança'),
            const _SectionContent(
              content: 'Implementamos medidas de segurança padrão da indústria para '
                  'proteger suas informações pessoais.',
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: '5. Contato'),
            const _SectionContent(
              content: 'Se tiver dúvidas sobre esta política, entre em contato '
                  'através do suporte do aplicativo.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  const _SectionContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
