import 'package:flutter/material.dart';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/core/utils/app_colors.dart'; // <--- Import da cor correta

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
    
    // Hack para telas grandes onde não precisa de scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent <= 0) {
          setState(() {
            _hasScrolledToEnd = true;
          });
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Se chegou perto do fim
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
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
        title: const Text('Termos e Privacidade'),
        automaticallyImplyLeading: false, // Sem botão de voltar
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Termos de Uso', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                            'Bem-vindo ao RunSafe. Ao utilizar este aplicativo, você concorda com nossos termos.\n\n'
                            '1. COLETA DE DADOS: Coletamos sua localização para monitorar suas corridas e garantir sua segurança.\n\n'
                            '2. ARMAZENAMENTO: Seus dados de metas e rotas são salvos localmente no seu dispositivo.\n\n'
                            '3. RESPONSABILIDADE: O uso do aplicativo durante atividades físicas é de sua total responsabilidade.\n\n'
                            '4. SEGURANÇA: Recomendamos não compartilhar rotas sensíveis publicamente.\n\n'
                            'Role até o final para habilitar o botão de aceite.'),
                        const SizedBox(height: 24),
                        Text('LGPD', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                            'Respeitamos sua privacidade. Você pode limpar seus dados nas configurações do aplicativo a qualquer momento.\n\n'
                            'Fim dos termos.'),
                         const SizedBox(height: 100), // Espaço para forçar o scroll
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(
                "Li e concordo com os termos.",
                style: TextStyle(
                  color: _hasScrolledToEnd ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: !_hasScrolledToEnd 
                ? const Text("Role o texto até o fim para liberar.", style: TextStyle(color: Colors.red, fontSize: 12))
                : null,
              value: _isChecked,
              onChanged: _hasScrolledToEnd
                  ? (bool? value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    }
                  : null, 
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                // CORRIGIDO AQUI: Usa a cor oficial do App
                backgroundColor: _isChecked ? AppColors.emerald : Colors.grey,
              ),
              onPressed: _isChecked
                  ? () async {
                      // Salva
                      await _storageService.saveUserConsent();
                      
                      if (mounted) {
                        // Navega para Home
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                      }
                    }
                  : null,
              child: const Text('Entendi e Concordo', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}