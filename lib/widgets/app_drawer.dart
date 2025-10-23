import 'package:flutter/material.dart';
import 'package:runsafe/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const String userName = "Bolivar Torres Neto";
    const String userInitials = "BT";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader( // <-- 'const' removido daqui porque a decoração não é const
            accountName: const Text(
              userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: const Text("Visualizar perfil"),
            currentAccountPicture: const CircleAvatar( // <-- 'const' adicionado
              backgroundColor: AppColors.navy,
              child: Text(
                userInitials,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: const BoxDecoration( // <-- 'const' adicionado
              color: AppColors.emerald,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}