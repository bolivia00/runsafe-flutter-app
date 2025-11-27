import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bem-vindo ao RunSafe',
      description: 'Rastreie suas corridas com segurança',
      icon: Icons.location_on,
    ),
    OnboardingPage(
      title: 'Defina seus Objetivos',
      description: 'Estabeleça metas semanais para suas corridas',
      icon: Icons.flag,
    ),
    OnboardingPage(
      title: 'Receba Alertas',
      description: 'Notificações de segurança em tempo real',
      icon: Icons.notifications,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        page.icon,
                        size: 120,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Começar' : 'Próximo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
