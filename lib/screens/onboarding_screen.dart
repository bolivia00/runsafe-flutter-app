import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:runsafe/utils/app_colors.dart';

// 1. Convertemos para StatefulWidget para podermos controlar em qual página o usuário está.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // 2. Controlador para o PageView, nos permite animar a troca de páginas.
  final _pageController = PageController();
  // Variável para guardar a página atual (começa na página 0).
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Adicionamos um "ouvinte" que nos avisa sempre que a página muda.
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Limpamos o controlador ao sair da tela.
    super.dispose();
  }

  // 3. Criamos uma lista com o conteúdo de cada página do onboarding.
  final List<Widget> _onboardingPages = [
    const _OnboardingPage(
      icon: Icons.run_circle_outlined,
      title: 'Bem-vindo ao RunSafe!',
      description: 'Mapeie suas rotas de corrida com alertas de segurança e corra com mais tranquilidade.',
    ),
    const _OnboardingPage(
      icon: Icons.map_outlined,
      title: 'Rotas Inteligentes',
      description: 'Descubra os melhores e mais seguros caminhos para correr na sua cidade, baseados em dados da comunidade.',
    ),
    const _OnboardingPage(
      icon: Icons.security_outlined,
      title: 'Sua Segurança em Foco',
      description: 'Receba alertas em tempo real sobre áreas de risco e compartilhe sua localização com contatos de confiança.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4. PageView é o widget que cria o efeito de "deslizar" as páginas.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onboardingPages.length,
                  itemBuilder: (context, index) {
                    return _onboardingPages[index];
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 5. O DotsIndicator, que mostra em qual página estamos.
              DotsIndicator(
                dotsCount: _onboardingPages.length,
                position: _currentPage.round(),
                decorator: DotsDecorator(
                  color: Colors.grey.shade400,
                  activeColor: AppColors.emerald,
                  size: const Size.square(9.0),
                  activeSize: const Size(18.0, 9.0),
                  activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                ),
              ),
              const SizedBox(height: 48),

              // 6. Botões de ação na parte inferior.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão "Pular"
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/privacy');
                    },
                    child: const Text('PULAR'),
                  ),

                  // Botão "Avançar" ou "Concluir"
                  ElevatedButton(
                    onPressed: () {
                      // Se não for a última página, avança para a próxima.
                      if (_currentPage < _onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        // Se for a última página, vai para a tela de privacidade.
                        Navigator.of(context).pushNamed('/privacy');
                      }
                    },
                    child: Text(
                      _currentPage < _onboardingPages.length - 1 ? 'AVANÇAR' : 'CONCLUIR',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para não repetir o layout de cada página.
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: AppColors.emerald),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}