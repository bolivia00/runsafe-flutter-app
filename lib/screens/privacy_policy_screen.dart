import 'package:flutter/material.dart';
import 'package:runsafe/services/storage_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // 1. Criamos o "espião" para a barra de rolagem.
  final ScrollController _scrollController = ScrollController();
  
  bool _isChecked = false;
  // 2. Nova variável para saber se o usuário já rolou até o fim.
  bool _hasScrolledToEnd = false; 
  
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // 3. Dizemos ao nosso "espião" para nos avisar sempre que a rolagem mudar.
    _scrollController.addListener(_onScroll);
  }

  // 4. Esta função é chamada toda vez que o usuário rola a página.
  void _onScroll() {
    // Verificamos se a posição atual da rolagem é igual à posição máxima possível.
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Se for, e se ainda não tínhamos registrado isso, atualizamos o estado.
      if (!_hasScrolledToEnd) {
        setState(() {
          _hasScrolledToEnd = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // 5. É importante "dispensar" o espião quando a tela for fechada para não usar memória à toa.
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
              // 6. Conectamos nosso "espião" (ScrollController) ao widget de rolagem.
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
                    // Adicionei mais texto para garantir que a rolagem seja necessária.
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
              // 7. A MÁGICA FINAL: O checkbox só pode ser alterado se _hasScrolledToEnd for verdadeiro.
              // Também mudamos a cor do texto para dar uma dica visual ao usuário.
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
                  : null, // O "null" aqui desabilita o checkbox.
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChecked
                  ? () async {
                      await _storageService.saveUserConsent();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                      }
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