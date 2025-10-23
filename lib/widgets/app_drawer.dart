import 'package:flutter/material.dart';
import 'package:runsafe/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos seu nome "Bolivar Torres" para pegar as iniciais "BT"
    const String userName = "Bolivar Torres Neto";
    const String userInitials = "BT";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: const Text("Visualizar perfil"), // Podemos mudar isso depois
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.navy, // Cor de fundo das iniciais
              child: const Text(
                userInitials,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald, // Cor de fundo do cabeçalho
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              // Fecha o menu e não faz nada, pois já estamos na Home.
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              // Aqui podemos adicionar a navegação para as configurações no futuro
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}