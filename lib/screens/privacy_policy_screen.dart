import 'package:flutter/material.dart';
import 'package:runsafe/services/storage_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isChecked = false;
  bool _hasScrolledToEnd = false; 
  
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_hasScrolledToEnd) {
        setState(() {
          _hasScrolledToEnd = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uso da Localização',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Para mapear suas rotas e fornecer alertas de segurança, o RunSafe precisa acessar a localização do seu dispositivo. Você pode negar essa permissão e inserir suas rotas manualmente. Seus dados são processados em tempo real para garantir sua segurança e não são armazenados por mais tempo que o necessário.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n\nExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'),
                    const SizedBox(height: 24),
                    Text(
                      'LGPD e Seus Dados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Respeitamos a sua privacidade. Seus dados de localização são utilizados exclusivamente para as funcionalidades do aplicativo e não são compartilhados com terceiros sem o seu consentimento explícito. Você pode gerenciar suas permissões a qualquer momento nas configurações do seu dispositivo.\n\nNossa política segue estritamente os padrões da Lei Geral de Proteção de Dados (LGPD), garantindo a você total controle sobre suas informações. Para mais detalhes, consulte nossa política de privacidade completa em nosso site. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(
                "Li e concordo com os termos.",
                style: TextStyle(
                  color: _hasScrolledToEnd ? Colors.black87 : Colors.grey,
                ),
              ),
              value: _isChecked,
              onChanged: _hasScrolledToEnd
                  ? (bool? value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    }
                  : null, 
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChecked
                  ? () async {
                      // --- INÍCIO DA CORREÇÃO DO LINT ---
                      // 1. Capturamos o Navigator ANTES do 'await'.
                      final navigator = Navigator.of(context);
                      
                      // 2. O 'await' (a "pausa" assíncrona) acontece.
                      await _storageService.saveUserConsent();
                      
                      // 3. Usamos o navigator capturado, dentro da checagem 'mounted'.
                      if (mounted) {
                        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                      }
                      // --- FIM DA CORREÇÃO DO LINT ---
                    }
                  : null,
              child: const Text('Entendi e Concordo'),
            ),
          ],
        ),
      ),
    );
  }
}