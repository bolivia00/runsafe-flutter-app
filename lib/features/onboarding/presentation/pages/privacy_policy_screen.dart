import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/core/utils/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String _currentTermsVersion = '1.0';
  
  final ScrollController _scrollController = ScrollController();
  
  bool _isChecked = false;
  bool _hasScrolledToEnd = false;
  bool _isLoading = true;
  String _termsContent = '';
  
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTermsContent();
    
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
  
  Future<void> _loadTermsContent() async {
    try {
      final content = await rootBundle.loadString('assets/terms_and_privacy.md');
      if (mounted) {
        setState(() {
          _termsContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsContent = 'Erro ao carregar termos. Por favor, tente novamente.';
          _isLoading = false;
        });
      }
    }
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
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMarkdownContent(),
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
                      backgroundColor: _isChecked ? AppColors.emerald : Colors.grey,
                      elevation: _isChecked ? 2 : 0,
                    ),
                    onPressed: _isChecked
                        ? () async {
                            final navigator = Navigator.of(context);
                            await _storageService.saveUserConsent(version: _currentTermsVersion);
                            if (!mounted) return;
                            navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                          }
                        : null,
                    child: const Text(
                      'Entendi e Concordo',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildMarkdownContent() {
    // Renderização simples do markdown (sem pacote externo)
    final lines = _termsContent.split('\n');
    final widgets = <Widget>[];
    
    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Text(
          line.substring(2),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
        widgets.add(const SizedBox(height: 12));
      } else if (line.startsWith('## ')) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(Text(
          line.substring(3),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ));
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('### ')) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(Text(
          line.substring(4),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ));
        widgets.add(const SizedBox(height: 6));
      } else if (line.startsWith('#### ')) {
        widgets.add(Text(
          line.substring(5),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ));
        widgets.add(const SizedBox(height: 4));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        widgets.add(Text(
          line.replaceAll('**', ''),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
        widgets.add(const SizedBox(height: 4));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('---')) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)));
        widgets.add(const SizedBox(height: 8));
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.contains('✅') || line.contains('❌')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(
            line,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ));
      } else {
        widgets.add(Text(
          line,
          style: Theme.of(context).textTheme.bodyMedium,
        ));
        widgets.add(const SizedBox(height: 4));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}