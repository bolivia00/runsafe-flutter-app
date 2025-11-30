import 'package:flutter/material.dart';
import 'package:runsafe/core/utils/app_colors.dart';
import 'package:runsafe/core/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RunSafe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy, // Cor do texto/ícones
      ),
      drawer: const AppDrawer(), // O Menu Lateral
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartão de Boas-vindas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.emerald.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Bem-vindo ao RunSafe!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Rastreie suas corridas com segurança',
                      style: TextStyle(color: AppColors.gray),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Acesso Rápido',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 16),

              // Grade de Botões
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.flag,
                      label: 'Metas Semanais',
                      route: '/weekly-goals',
                      color: AppColors.emerald,
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.notifications_active,
                      label: 'Alertas',
                      route: '/safety-alerts',
                      color: AppColors.emerald,
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.location_on,
                      label: 'Waypoints',
                      route: '/waypoints',
                      color: AppColors.emerald,
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.route,
                      label: 'Rotas',
                      route: '/running-routes',
                      color: AppColors.emerald,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                 color: color.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}